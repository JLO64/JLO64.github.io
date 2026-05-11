require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'open-uri'
require 'mini_magick'

module Jekyll
  # Generator plugin to fetch all rated movies from TMDB API (v4) and persist
  # the data to _data/tmdb_rated_movies.json. Also derives
  # _data/tmdb_recently_rated_movies.json (last 5 rated) for the homepage.
  # Falls back to committed files if the API is unavailable.
  #
  # Uses TMDB v4 API to get account_rating.created_at for accurate date grouping.
  # Requires TMDB_API_KEY env var (API Read Access Token).
  class TmdbRatedMoviesGenerator < Generator
    safe true
    include DataSyncHelpers
    attr_accessor :site

    TMDB_ACCOUNT_OBJECT_ID = '6a0147005ba946588af88fa7'
    IMAGE_BASE             = 'https://image.tmdb.org/t/p/w500'
    DATA_FILE              = '_data/tmdb_rated_movies.json'
    RECENT_FILE            = '_data/tmdb_recently_rated_movies.json'
    RECENT_LIMIT           = 5

    def generate(site)
      self.site = site

      # If data is fresh, just register any existing poster images with Jekyll's
      # static file system so they survive the build. No API call needed.
      if skip_if_data_fresh?(DATA_FILE, source: site.source) &&
         File.exist?(File.join(site.source, RECENT_FILE))
        register_poster_images(site)
        return
      end

      # Load .env
      env_path = File.join(site.source, '.env')
      if File.exist?(env_path)
        File.foreach(env_path) do |line|
          next if line.strip.start_with?('#') || line.strip.empty?
          key, value = line.strip.split('=', 2)
          ENV[key] ||= value
        end
      end

      token = ENV['TMDB_API_KEY']
      unless token && !token.empty?
        Jekyll.logger.warn 'TMDB Movies:', 'No TMDB_API_KEY — using cached data'
        return
      end

      auth = if token.start_with?('Bearer ')
               token
             else
               "Bearer #{token}"
             end

      # Fetch genre map once (small, static)
      genre_map = fetch_genre_map(auth)
      unless genre_map
        Jekyll.logger.warn 'TMDB Movies:', 'Failed to fetch genre map — keeping existing data'
        return
      end

      # Fetch all rated movies across all pages
      movies = fetch_all_rated_movies(auth)
      unless movies
        Jekyll.logger.warn 'TMDB Movies:', 'API fetch failed — keeping existing data'
        return
      end

      if movies.empty?
        Jekyll.logger.warn 'TMDB Movies:', 'No rated movies returned — keeping existing data'
        return
      end

      images_dir = File.join(site.source, 'assets', 'images', 'tmdb', 'movies')
      FileUtils.mkdir_p(images_dir)

      records = movies.filter_map do |m|
        poster_path    = m['poster_path']
        cover_file     = poster_path ? download_poster(poster_path, images_dir) : nil
        release_date   = m['release_date']
        account_rating = m['account_rating'] || {}
        rated_at       = account_rating['created_at']
        rating         = account_rating['value'] || m['rating']
        year           = if rated_at.to_s.strip.empty?
                           if release_date.to_s.strip.empty?
                             'Unknown'
                           else
                             release_date[0, 4]
                           end
                         else
                           rated_at[0, 4]
                         end
        genres = (m['genre_ids'] || []).map { |gid| genre_map[gid] }.compact

        {
          'tmdb_id'          => m['id'],
          'title'            => m['title'],
          'original_title'   => m['original_title'],
          'rating'           => rating,
          'release_date'     => release_date,
          'rated_at'         => rated_at,
          'year'             => year,
          'overview'         => m['overview'],
          'genres'           => genres,
          'poster_url'       => poster_path ? "#{IMAGE_BASE}#{poster_path}" : nil,
          'poster_filepath'  => cover_file,
          'vote_average'     => m['vote_average'],
          'vote_count'       => m['vote_count'],
          'popularity'       => m['popularity'],
          'original_language' => m['original_language']
        }
      end

      data_dir = File.join(site.source, '_data')
      FileUtils.mkdir_p(data_dir)

      # Register poster images with Jekyll's static file system so they are
      # written to _site/. Generators run after static files are copied,
      # so newly downloaded images must be registered manually.
      register_poster_images(site)

      File.write(File.join(site.source, DATA_FILE), JSON.pretty_generate(records))
      mark_data_synced(DATA_FILE, source: site.source)
      Jekyll.logger.info 'TMDB Movies:', "Synced #{records.size} rated movies to #{DATA_FILE}"

      # Derive recently rated (already sorted newest-first from the API)
      recent = records.first(RECENT_LIMIT)
      File.write(File.join(site.source, RECENT_FILE), JSON.pretty_generate(recent))
      Jekyll.logger.info 'TMDB Movies:', "Synced #{recent.size} recently rated movies to #{RECENT_FILE}"
    end

    private

    # Register all poster images in the source directory with Jekyll's
    # static file system so they are written to _site/ on every build.
    def register_poster_images(site)
      images_dir = File.join(site.source, 'assets', 'images', 'tmdb', 'movies')
      return unless File.directory?(images_dir)
      Dir.glob(File.join(images_dir, '*.webp')).each do |img|
        static_file = Jekyll::StaticFile.new(site, site.source, File.join('assets', 'images', 'tmdb', 'movies'), File.basename(img))
        site.static_files << static_file unless site.static_files.any? { |sf| sf.path == static_file.path }
      end
    end

    # Fetch the genre map: { genre_id => genre_name }
    def fetch_genre_map(auth)
      uri = URI.parse('https://api.themoviedb.org/3/genre/movie/list?language=en-US')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 20

      req = Net::HTTP::Get.new(uri.request_uri)
      req['Authorization'] = auth
      req['Accept'] = 'application/json'

      res = http.request(req)
      unless res.is_a?(Net::HTTPSuccess)
        Jekyll.logger.warn 'TMDB Movies genre error:',
                           "HTTP #{res.code}: #{res.body[0, 300]}"
        return nil
      end

      data = JSON.parse(res.body)
      genres = data['genres'] || []
      genres.each_with_object({}) { |g, map| map[g['id']] = g['name'] }
    rescue StandardError => e
      Jekyll.logger.warn 'TMDB Movies genre error:', e.message
      nil
    end

    # Paginate through all rated movies via the v4 API.
    def fetch_all_rated_movies(auth)
      all_movies = []
      page = 1

      loop do
        uri = URI.parse("https://api.themoviedb.org/4/account/#{TMDB_ACCOUNT_OBJECT_ID}/movie/rated")
        uri.query = URI.encode_www_form(
          sort_by: 'created_at.desc',
          language: 'en-US',
          page: page
        )

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 20

        req = Net::HTTP::Get.new(uri.request_uri)
        req['Authorization'] = auth
        req['Accept'] = 'application/json'

        res = http.request(req)
        unless res.is_a?(Net::HTTPSuccess)
          Jekyll.logger.warn 'TMDB Movies:', "HTTP #{res.code} on page #{page}"
          return page == 1 ? nil : all_movies
        end

        data = JSON.parse(res.body)
        results = data['results'] || []
        all_movies.concat(results)

        total_pages = data['total_pages'].to_i
        break if page >= total_pages || results.empty?

        page += 1
      end

      all_movies
    rescue StandardError => e
      Jekyll.logger.warn 'TMDB Movies API error:', e.message
      all_movies.empty? ? nil : all_movies
    end

    # Download a poster from TMDB, convert to WebP, return relative path.
    def download_poster(poster_path, images_dir)
      return nil unless poster_path

      filepath = File.join(images_dir, "#{poster_path.gsub('/', '_')}.webp")

      unless File.exist?(filepath)
        url = "#{IMAGE_BASE}#{poster_path}"
        fetched = URI.open(url)
        image = MiniMagick::Image.read(fetched)
        image.format 'webp'
        image.write filepath
      end

      # Return relative path from site root
      filepath.sub("#{site.source}/", '')
    rescue StandardError => e
      Jekyll.logger.warn "TMDB Movies poster error for #{poster_path}:", e.message
      nil
    end
  end
end
