require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'open-uri'
require 'mini_magick'

module Jekyll
  # Generator plugin to fetch currently watching anime from MyAnimeList.
  # Writes to _data/mal_currently_watching.json on each successful build.
  # Fails silently if credentials are missing or the API is unavailable.
  #
  # Reads from .env:
  #   MAL_ACCESS_TOKEN     — OAuth Bearer token (set via _scripts/mal_auth.rb)
  #   MAL_REFRESH_TOKEN    — OAuth refresh token for auto-renewal
  #   MAL_TOKEN_EXPIRES_AT — Unix timestamp of access token expiry
  #   MAL_Client_ID        — API client ID (fallback if no OAuth tokens)
  #   MAL_Client_Secret    — API client secret (needed for token refresh)
  class MalCurrentlyWatchingGenerator < Generator
    safe true

    MAL_USERNAME = 'JLO64'
    MAL_FIELDS   = 'id,title,main_picture,my_list_status{score,num_episodes_watched,start_date},num_episodes'

    def generate(site)
      env_path = File.join(site.source, '.env')
      load_env(env_path)

      auth_header = resolve_auth_header(env_path)
      return unless auth_header

      entries = fetch_currently_watching(auth_header)
      return unless entries

      images_dir = File.join(site.source, 'assets', 'images', 'mal')
      FileUtils.mkdir_p(images_dir)

      anime = entries.filter_map do |entry|
        node = entry['node']
        next unless node

        list_status    = node['my_list_status'] || {}
        cover_url      = node.dig('main_picture', 'large') || node.dig('main_picture', 'medium')
        cover_filepath = download_cover(cover_url, node['id'], images_dir)

        {
          'id'                   => node['id'],
          'title'                => node['title'],
          'cover_url'            => cover_url,
          'cover_filepath'       => cover_filepath,
          'score'                => list_status['score'],
          'num_episodes'         => node['num_episodes'],
          'num_episodes_watched' => list_status['num_episodes_watched']
        }
      end

      data_dir = File.join(site.source, '_data')
      FileUtils.mkdir_p(data_dir)
      File.write(File.join(data_dir, 'mal_currently_watching.json'), JSON.pretty_generate(anime))
      Jekyll.logger.info "MAL:", "Synced #{anime.size} currently watching anime to mal_currently_watching.json"
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

      Jekyll.logger.info "MAL:", "Refreshing access token..."

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
        Jekyll.logger.warn "MAL:", "Token refresh failed (#{res.code}) — using existing token"
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

      Jekyll.logger.info "MAL:", "Token refreshed (expires #{Time.at(new_expires).strftime('%Y-%m-%d')})"
      new_access
    rescue StandardError => e
      Jekyll.logger.warn "MAL token refresh error:", e.message
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

    def fetch_currently_watching(auth_header)
      fields_enc = URI.encode_www_form_component(MAL_FIELDS)
      url  = "https://api.myanimelist.net/v2/users/#{MAL_USERNAME}/animelist" \
             "?status=watching&fields=#{fields_enc}&limit=100"

      uri  = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request[auth_header[0]] = auth_header[1]

      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)['data']
    rescue StandardError => e
      Jekyll.logger.warn "MAL API error:", e.message
      nil
    end

    def download_cover(url, anime_id, images_dir)
      return nil unless url

      filename = "mal_anime_#{anime_id}.webp"
      filepath = File.join(images_dir, filename)

      unless File.exist?(filepath)
        fetched = URI.open(url)
        image   = MiniMagick::Image.read(fetched)
        image.format 'webp'
        image.write filepath
      end

      File.join('assets', 'images', 'mal', filename)
    rescue StandardError => e
      Jekyll.logger.warn "MAL image error for #{url}:", e.message
      nil
    end
  end
end
