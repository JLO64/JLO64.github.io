require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'open-uri'
require 'mini_magick'

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

      # GraphQL query to fetch books with status_id = 2 (currently reading), including author
      query = <<~GRAPHQL
        query list {
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
              contributions {
                author {
                  name
                }
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

      # Download and convert each book image to WebP, and add local filepath to JSON
      if (books = result.dig("data", "list_books")).is_a?(Array)
        images_dir = File.join(site.source, 'assets', 'images', 'hardcover')
        FileUtils.mkdir_p(images_dir)
        books.each do |entry|
          image_info = entry.dig("book", "image")
          next unless image_info && image_info["url"]
          image_url = image_info["url"]
          begin
            uri = URI.parse(image_url)
            ext = File.extname(uri.path)
            basename = File.basename(uri.path, ext)
            webp_filename = "#{basename}.webp"
            webp_path = File.join(images_dir, webp_filename)
            # Skip if already exists
            unless File.exist?(webp_path)
              fetched = URI.open(image_url)
              image = MiniMagick::Image.read(fetched)
              image.format "webp"
              image.write webp_path
            end
            # Save relative filepath
            image_info["filepath"] = File.join('assets', 'images', 'hardcover', webp_filename)
          rescue StandardError => e
            Jekyll.logger.warn "Hardcover image error for #{image_url}:", e.message
          end
        end
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
