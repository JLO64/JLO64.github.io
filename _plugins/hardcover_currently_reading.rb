require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

module Jekyll
  # Generator plugin to fetch currently reading books from Hardcover API
  class HardcoverCurrentlyReadingGenerator < Generator
    safe true

    def generate(site)
      # Load environment variables from .env (if present)
      env_path = File.join(site.source, '.env')
      if File.exist?(env_path)
        File.foreach(env_path) do |line|
          next if line.strip.start_with?('#') || line.strip.empty?
          key, value = line.strip.split('=', 2)
          ENV[key] ||= value
        end
      end

      # Expect token for Hardcover in HARDCOVER_AUTHORIZATION or HARDCOVER_TOKEN
      token = ENV['HARDCOVER_AUTHORIZATION'] || ENV['HARDCOVER_TOKEN']
      return unless token && !token.empty?

      # GraphQL query to fetch books with status_id = 2 (currently reading)
      query = <<~GRAPHQL
        query books_currently_reading {
          list_books(
            where: {user_books: {user_id: {_eq: 35418}, status_id: {_eq: 2}}}
            distinct_on: book_id
            offset: 0
          ) {
            book {
              title
              image {
                url
              }
            }
          }
        }
      GRAPHQL

      # Prepare HTTP request
      endpoint = 'https://api.hardcover.app/v1/graphql'
      uri = URI.parse(endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      request = Net::HTTP::Post.new(uri.request_uri)
      # Set authentication header (case-insensitive)
      request['Authorization'] = token
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate({ query: query })

      # Execute and parse response, silently skip on failure
      begin
        response = http.request(request)
        return unless response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
      rescue StandardError => e
        Jekyll.logger.warn "Hardcover API error:", e.message
        return
      end

      # Write result to _data/hardcover_currently_reading.json
      data_dir = File.join(site.source, '_data')
      FileUtils.mkdir_p(data_dir) unless Dir.exist?(data_dir)
      file_path = File.join(data_dir, 'hardcover_currently_reading.json')
      File.open(file_path, 'w') do |f|
        f.write(JSON.pretty_generate(result))
      end
    end
  end
end
