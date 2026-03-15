require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'open-uri'
require 'mini_magick'

module Jekyll
  # Generator plugin to fetch all read books from Hardcover API and persist
  # the data to _data/hardcover_all_read.json. If the API is unavailable, the
  # existing file is left untouched so the site continues to build from cache.
  class HardcoverAllReadGenerator < Generator
    safe true

    QUERY = <<~GRAPHQL
      query AllReadBooks {
        me {
          user_books(
            where: {status_id: {_eq: 3}},
            limit: 500,
            order_by: {last_read_date: desc_nulls_last}
          ) {
            id
            rating
            last_read_date
            date_added
            user_book_reads {
              started_at
              finished_at
              edition {
                id
                title
                image { url }
                contributions {
                  author { name }
                }
              }
            }
            book { id title }
          }
        }
      }
    GRAPHQL

    def generate(site)
      # Load .env
      env_path = File.join(site.source, '.env')
      if File.exist?(env_path)
        File.foreach(env_path) do |line|
          next if line.strip.start_with?('#') || line.strip.empty?
          key, value = line.strip.split('=', 2)
          ENV[key] ||= value
        end
      end

      token = ENV['HARDCOVER_AUTHORIZATION'] || ENV['HARDCOVER_TOKEN']
      data_file = File.join(site.source, '_data', 'hardcover_all_read.json')

      unless token && !token.empty?
        Jekyll.logger.warn "Hardcover:", "No token — using cached hardcover_all_read.json" if File.exist?(data_file)
        return
      end

      result = fetch_graphql(QUERY, token)
      return unless result

      user_books = result.dig("data", "me", 0, "user_books")
      return unless user_books.is_a?(Array)

      images_dir = File.join(site.source, 'assets', 'images', 'hardcover')
      FileUtils.mkdir_p(images_dir)

      books = user_books.filter_map do |ub|
        read = ub["user_book_reads"]&.first
        next unless read

        edition = read["edition"]
        next unless edition

        cover_filepath = download_cover(edition.dig("image", "url"), images_dir)
        authors = (edition["contributions"] || []).map { |c| c.dig("author", "name") }.compact

        # Derive the best available date for grouping and sorting
        date_str = ub["last_read_date"] || read["finished_at"] || ub["date_added"]
        year = date_str ? date_str[0, 4] : "Unknown"

        {
          "id"             => ub["id"],
          "book_id"        => ub.dig("book", "id"),
          "edition_id"     => edition["id"],
          "title"          => edition["title"] || ub.dig("book", "title"),
          "authors"        => authors,
          "rating"         => ub["rating"],
          "started_at"     => read["started_at"],
          "finished_at"    => read["finished_at"],
          "last_read_date" => ub["last_read_date"],
          "date_added"     => ub["date_added"],
          "year"           => year,
          "cover_url"      => edition.dig("image", "url"),
          "cover_filepath" => cover_filepath
        }
      end

      FileUtils.mkdir_p(File.join(site.source, '_data'))
      File.write(data_file, JSON.pretty_generate(books))
      Jekyll.logger.info "Hardcover:", "Synced #{books.size} read books to hardcover_all_read.json"
    end

    private

    def fetch_graphql(query, token)
      uri = URI.parse('https://api.hardcover.app/v1/graphql')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Authorization'] = token
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate({ query: query })
      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    rescue StandardError => e
      Jekyll.logger.warn "Hardcover API error:", e.message
      nil
    end

    def download_cover(url, images_dir)
      return nil unless url
      uri = URI.parse(url)
      ext = File.extname(uri.path)
      basename = File.basename(uri.path, ext)
      webp_filename = "#{basename}.webp"
      webp_path = File.join(images_dir, webp_filename)
      unless File.exist?(webp_path)
        fetched = URI.open(url)
        image = MiniMagick::Image.read(fetched)
        image.format "webp"
        image.write webp_path
      end
      File.join('assets', 'images', 'hardcover', webp_filename)
    rescue StandardError => e
      Jekyll.logger.warn "Hardcover image error for #{url}:", e.message
      nil
    end
  end
end
