require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'fileutils'
require 'stringio'
require 'mini_magick'

module Jekyll
  # Generator plugin to fetch all games from HowLongToBeat via the internal
  # /api/user/{user_id}/games/list endpoint (no API token required) and
  # persist to _data/hltb_games_list.json. Also derives
  # _data/hltb_currently_playing.json for the homepage section.
  # Falls back to committed files if the network is unavailable.
  class HltbGamesListGenerator < Generator
    safe true

    HLTB_USERNAME = 'JLO64'
    HLTB_USER_ID  = 662984

    # Map list flags (in priority order) to status strings.
    LIST_STATUS = [
      ['list_playing',  'playing'],
      ['list_backlog',  'backlog'],
      ['list_replay',   'replay'],
      ['list_custom',   'on_hold'],
      ['list_custom2',  'custom2'],
      ['list_custom3',  'custom3'],
      ['list_comp',     'completed'],
      ['list_retired',  'retired']
    ].freeze

    def generate(site)
      data_file  = File.join(site.source, '_data', 'hltb_games_list.json')
      images_dir = File.join(site.source, 'assets', 'images', 'hltb')
      FileUtils.mkdir_p(images_dir)

      raw = fetch_all
      unless raw
        Jekyll.logger.warn 'HLTB Games:', 'API fetch failed — keeping existing hltb_games_list.json'
        return
      end

      if raw.empty?
        Jekyll.logger.warn 'HLTB Games:', 'No games returned — keeping existing hltb_games_list.json'
        return
      end

      all_games        = []
      currently_playing = []

      raw.each do |entry|
        game_id    = entry['game_id']
        status_str = LIST_STATUS.find { |flag, _| entry[flag] == 1 }&.last || 'unknown'

        finish_date = parse_date(entry['date_complete'])
        start_date  = parse_date(entry['date_start'])
        added_date  = entry['date_added']&.then { |d| d[0..9] }
        sort_date   = finish_date || start_date || added_date || '0000-00-00'

        cover_url      = entry['game_image'] ? "https://howlongtobeat.com/games/#{entry['game_image']}" : nil
        cover_filepath = download_cover(cover_url, "hltb_game_#{game_id}", images_dir)

        record = {
          'id'             => entry['id'],
          'game_id'        => game_id,
          'title'          => entry['custom_title'].to_s.strip,
          'status'         => status_str,
          'platform'       => entry['platform'] == 'Xbox Series X/S' ? 'Xbox Series S' : entry['platform'],
          'storefront'     => entry['play_storefront'],
          'cover_url'      => cover_url,
          'cover_filepath' => cover_filepath,
          'review_score'   => entry['review_score']&.>(0) ? (entry['review_score'] / 10.0).then { |s| s == s.to_i ? s.to_i : s } : nil,
          'review_notes'   => entry['review_notes'].to_s.strip.then { |s| s.empty? ? nil : s },
          'comp_main'      => seconds_to_hours(entry['comp_main']),
          'comp_plus'      => seconds_to_hours(entry['comp_plus']),
          'comp_100'       => seconds_to_hours(entry['comp_100']),
          'play_count'     => entry['play_count'],
          'date_start'     => start_date,
          'date_complete'  => finish_date,
          'date_added'     => added_date,
          'sort_date'      => sort_date
        }

        all_games << record
        currently_playing << record.slice(
          'id', 'game_id', 'title', 'cover_url', 'cover_filepath', 'platform', 'storefront'
        ) if status_str == 'playing'
      end

      data_dir = File.join(site.source, '_data')
      FileUtils.mkdir_p(data_dir)

      File.write(data_file, JSON.pretty_generate(all_games))
      Jekyll.logger.info 'HLTB Games:', "Synced #{all_games.size} total games to hltb_games_list.json"

      File.write(File.join(data_dir, 'hltb_currently_playing.json'), JSON.pretty_generate(currently_playing))
      Jekyll.logger.info 'HLTB Games:', "Synced #{currently_playing.size} currently playing to hltb_currently_playing.json"
    end

    private

    def fetch_all
      url = "https://howlongtobeat.com/api/user/#{HLTB_USER_ID}/games/list"
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 20

      body = JSON.generate(
        user_id:         HLTB_USER_ID,
        toggleType:      'Multi List',
        lists:           %w[playing backlog replays custom custom2 custom3 completed retired],
        set_playstyle:   'comp_plus_h',
        name:            '',
        platform:        '',
        storefront:      '',
        sortBy:          '',
        sortFlip:        false,
        view:            'list',
        random:          0,
        limit:           500,
        currentUserHome: false
      )

      req = Net::HTTP::Post.new(uri.request_uri)
      req['Content-Type'] = 'application/json'
      req['Referer']      = "https://howlongtobeat.com/user/#{HLTB_USERNAME}/games"
      req['User-Agent']   = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      req.body = body

      res = http.request(req)
      unless res.is_a?(Net::HTTPSuccess)
        Jekyll.logger.warn 'HLTB Games:', "HTTP #{res.code} — stopping"
        return nil
      end

      data = JSON.parse(res.body)
      data.dig('data', 'gamesList')
    rescue StandardError => e
      Jekyll.logger.warn 'HLTB Games API error:', e.message
      nil
    end

    # Convert "YYYY-MM-DD" dates; treat "0000-00-00" as absent.
    def parse_date(str)
      return nil if str.nil? || str.strip.empty? || str == '0000-00-00'
      str.strip[0..9]
    rescue StandardError
      nil
    end

    # Convert seconds to rounded hours; return nil if zero/absent.
    def seconds_to_hours(seconds)
      return nil if seconds.nil? || seconds == 0
      (seconds / 3600.0).round(1)
    end

    def download_cover(url, basename, images_dir)
      return nil unless url

      filepath = File.join(images_dir, "#{basename}.webp")
      unless File.exist?(filepath)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 20

        req = Net::HTTP::Get.new(uri.request_uri)
        req['Referer']    = 'https://howlongtobeat.com/'
        req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'

        res = http.request(req)
        raise "HTTP #{res.code}" unless res.is_a?(Net::HTTPSuccess)

        image = MiniMagick::Image.read(StringIO.new(res.body))
        image.format 'webp'
        image.write filepath
      end

      File.join('assets', 'images', 'hltb', "#{basename}.webp")
    rescue StandardError => e
      Jekyll.logger.warn "HLTB Games image error for #{url}:", e.message
      nil
    end
  end
end
