require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'open-uri'
require 'mini_magick'

module Jekyll
  # Generator plugin to fetch reading/on_hold/completed/dropped manga from
  # MyAnimeList and persist to _data/mal_manga_list.json. Falls back to the
  # committed file if the API is unavailable or credentials are missing.
  #
  # Each entry includes a `status` field and a `sort_date` (finish_date,
  # start_date, or updated_at — whichever is available first) for page sorting.
  #
  # Reads from .env:
  #   MAL_ACCESS_TOKEN     — OAuth Bearer token (set via _scripts/mal_auth.rb)
  #   MAL_REFRESH_TOKEN    — OAuth refresh token for auto-renewal
  #   MAL_TOKEN_EXPIRES_AT — Unix timestamp of access token expiry
  #   MAL_Client_ID        — API client ID (fallback if no OAuth tokens)
  #   MAL_Client_Secret    — API client secret (needed for token refresh)
  class MalMangaListGenerator < Generator
    safe true

    MAL_USERNAME     = 'JLO64'
    MAL_STATUSES     = %w[reading on_hold completed dropped].freeze
    MAL_MANGA_FIELDS = 'id,title,main_picture,my_list_status{status,score,num_chapters_read,num_volumes_read,finish_date,start_date,updated_at},num_chapters,num_volumes'

    def generate(site)
      env_path = File.join(site.source, '.env')
      load_env(env_path)

      data_file = File.join(site.source, '_data', 'mal_manga_list.json')

      auth_header = resolve_auth_header(env_path)
      unless auth_header
        Jekyll.logger.warn "MAL Manga:", "No credentials — using cached mal_manga_list.json" if File.exist?(data_file)
        return
      end

      images_dir = File.join(site.source, 'assets', 'images', 'mal')
      FileUtils.mkdir_p(images_dir)

      all_manga = []

      MAL_STATUSES.each do |status|
        entries = fetch_by_status(status, auth_header)
        next unless entries

        entries.each do |entry|
          node = entry['node']
          next unless node

          list_status    = node['my_list_status'] || {}
          cover_url      = node.dig('main_picture', 'large') || node.dig('main_picture', 'medium')
          cover_filepath = download_cover(cover_url, node['id'], images_dir)

          updated_at_date = list_status['updated_at']&.slice(0, 10)
          sort_date = list_status['finish_date'] ||
                      list_status['start_date']  ||
                      updated_at_date            ||
                      '0000-00-00'

          all_manga << {
            'id'                 => node['id'],
            'title'              => node['title'],
            'status'             => status,
            'cover_url'          => cover_url,
            'cover_filepath'     => cover_filepath,
            'score'              => list_status['score'],
            'num_chapters'       => node['num_chapters'],
            'num_chapters_read'  => list_status['num_chapters_read'],
            'num_volumes'        => node['num_volumes'],
            'num_volumes_read'   => list_status['num_volumes_read'],
            'finish_date'        => list_status['finish_date'],
            'start_date'         => list_status['start_date'],
            'sort_date'          => sort_date
          }
        end

        Jekyll.logger.info "MAL Manga:", "Fetched #{entries.size} #{status} manga"
      end

      FileUtils.mkdir_p(File.join(site.source, '_data'))
      File.write(data_file, JSON.pretty_generate(all_manga))
      Jekyll.logger.info "MAL Manga:", "Synced #{all_manga.size} total manga to mal_manga_list.json"
    end

    private

    def load_env(env_path)
      return unless File.exist?(env_path)
      File.foreach(env_path) do |line|
        next if line.strip.start_with?('#') || line.strip.empty?
        key, value = line.strip.split('=', 2)
        ENV[key] ||= value
      end
    end

    def resolve_auth_header(env_path)
      access_token  = ENV['MAL_ACCESS_TOKEN']
      refresh_token = ENV['MAL_REFRESH_TOKEN']
      client_id     = ENV['MAL_Client_ID']

      if access_token && !access_token.empty?
        expires_at = ENV['MAL_TOKEN_EXPIRES_AT'].to_i
        if refresh_token && !refresh_token.empty? && Time.now.to_i >= expires_at - 86400
          access_token = refresh_access_token(env_path) || access_token
        end
        return ['Authorization', "Bearer #{access_token}"]
      end

      return ['X-MAL-CLIENT-ID', client_id] if client_id && !client_id.empty?

      nil
    end

    def refresh_access_token(env_path)
      client_id     = ENV['MAL_Client_ID']
      client_secret = ENV['MAL_Client_Secret']
      refresh_token = ENV['MAL_REFRESH_TOKEN']
      return nil unless client_id && client_secret && refresh_token

      Jekyll.logger.info "MAL Manga:", "Refreshing access token..."

      uri  = URI.parse('https://myanimelist.net/v1/oauth2/token')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri.request_uri)
      req['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        client_id:     client_id,
        client_secret: client_secret,
        grant_type:    'refresh_token',
        refresh_token: refresh_token
      )

      res = http.request(req)
      unless res.is_a?(Net::HTTPSuccess)
        Jekyll.logger.warn "MAL Manga:", "Token refresh failed (#{res.code}) — using existing token"
        return nil
      end

      data        = JSON.parse(res.body)
      new_access  = data['access_token']
      new_refresh = data['refresh_token']
      new_expires = Time.now.to_i + data['expires_in'].to_i

      update_env_file(env_path, {
        'MAL_ACCESS_TOKEN'     => new_access,
        'MAL_REFRESH_TOKEN'    => new_refresh,
        'MAL_TOKEN_EXPIRES_AT' => new_expires.to_s
      })

      ENV['MAL_ACCESS_TOKEN']     = new_access
      ENV['MAL_REFRESH_TOKEN']    = new_refresh
      ENV['MAL_TOKEN_EXPIRES_AT'] = new_expires.to_s

      Jekyll.logger.info "MAL Manga:", "Token refreshed (expires #{Time.at(new_expires).strftime('%Y-%m-%d')})"
      new_access
    rescue StandardError => e
      Jekyll.logger.warn "MAL Manga token refresh error:", e.message
      nil
    end

    def update_env_file(env_path, updates)
      return unless File.exist?(env_path)
      lines = File.readlines(env_path)
      updates.each do |key, value|
        found = false
        lines = lines.map do |line|
          if line.strip.start_with?("#{key}=")
            found = true
            "#{key}=#{value}\n"
          else
            line
          end
        end
        lines << "#{key}=#{value}\n" unless found
      end
      File.write(env_path, lines.join)
    end

    def fetch_by_status(status, auth_header)
      all_entries = []
      offset      = 0
      limit       = 1000

      loop do
        fields_enc = URI.encode_www_form_component(MAL_MANGA_FIELDS)
        url = "https://api.myanimelist.net/v2/users/#{MAL_USERNAME}/mangalist" \
              "?status=#{status}&fields=#{fields_enc}&limit=#{limit}&offset=#{offset}"

        uri  = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        request[auth_header[0]] = auth_header[1]

        response = http.request(request)
        break unless response.is_a?(Net::HTTPSuccess)

        result  = JSON.parse(response.body)
        entries = result['data'] || []
        all_entries.concat(entries)

        break if entries.size < limit
        break unless result.dig('paging', 'next')

        offset += limit
      end

      all_entries
    rescue StandardError => e
      Jekyll.logger.warn "MAL Manga API error (#{status}):", e.message
      nil
    end

    def download_cover(url, manga_id, images_dir)
      return nil unless url

      filename = "mal_manga_#{manga_id}.webp"
      filepath = File.join(images_dir, filename)

      unless File.exist?(filepath)
        fetched = URI.open(url)
        image   = MiniMagick::Image.read(fetched)
        image.format 'webp'
        image.write filepath
      end

      File.join('assets', 'images', 'mal', filename)
    rescue StandardError => e
      Jekyll.logger.warn "MAL Manga image error for #{url}:", e.message
      nil
    end
  end
end
