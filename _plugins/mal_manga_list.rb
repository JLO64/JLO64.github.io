require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'fileutils'
require 'open-uri'
require 'mini_magick'

module Jekyll
  # Generator plugin to fetch all manga from MyAnimeList via the public
  # load.json endpoint (no API token required) and persist to
  # _data/mal_manga_list.json. Also derives
  # _data/mal_currently_reading_manga.json for the homepage section.
  # Falls back to committed files if the network is unavailable.
  class MalMangaListGenerator < Generator
    safe true
    include DataSyncHelpers
    attr_accessor :site

    MAL_USERNAME = 'JLO64'
    PAGE_SIZE    = 300

    STATUS_MAP = {
      1 => 'reading',
      2 => 'completed',
      3 => 'on_hold',
      4 => 'dropped',
      6 => 'plan_to_read'
    }.freeze

    def generate(site)
      self.site = site
      data_file    = '_data/mal_manga_list.json'
      derived_file = '_data/mal_currently_reading_manga.json'
      # Only skip if the primary file is fresh AND the derived file also exists.
      # On a fresh clone, the primary is committed but the derived is not,
      # so we must still run to generate it.
      if skip_if_data_fresh?(data_file, source: site.source) && File.exist?(File.join(site.source, derived_file))
        return
      end

      data_file = File.join(site.source, '_data', 'mal_manga_list.json')
      images_dir = File.join(site.source, 'assets', 'images', 'mal')
      FileUtils.mkdir_p(images_dir)

      raw = fetch_all
      unless raw
        Jekyll.logger.warn 'MAL Manga:', 'API fetch failed — keeping existing mal_manga_list.json'
        return
      end

      if raw.empty?
        Jekyll.logger.warn 'MAL Manga:', 'No manga returned — keeping existing mal_manga_list.json'
        return
      end

      all_manga         = []
      currently_reading = []

      raw.each do |entry|
        manga_id   = entry['manga_id']
        status_int = entry['status']
        status_str = STATUS_MAP[status_int] || "unknown_#{status_int}"

        finish_date  = parse_date(entry['finish_date_string'])
        start_date   = parse_date(entry['start_date_string'])
        created_date = entry['created_at']&.then { |t| Time.at(t).strftime('%Y-%m-%d') rescue nil }
        sort_date    = finish_date || start_date || created_date || '0000-00-00'

        cover_url      = canonical_cover_url(entry['manga_image_path'], 'manga')
        cover_filepath = download_cover(cover_url, "mal_manga_#{manga_id}", images_dir)

        title = entry['title_localized'].to_s.strip
        title = entry['manga_title'].to_s.strip if title.empty?

        record = {
          'id'                => manga_id,
          'title'             => title,
          'status'            => status_str,
          'cover_url'         => cover_url,
          'cover_filepath'    => cover_filepath,
          'score'             => entry['score'],
          'num_chapters'      => entry['manga_num_chapters'],
          'num_chapters_read' => entry['num_read_chapters'],
          'num_volumes'       => entry['manga_num_volumes'],
          'num_volumes_read'  => entry['num_read_volumes'],
          'finish_date'       => finish_date,
          'start_date'        => start_date,
          'sort_date'         => sort_date
        }

        all_manga << record
        currently_reading << record.slice(
          'id', 'title', 'cover_url', 'cover_filepath', 'score',
          'num_chapters', 'num_chapters_read', 'num_volumes', 'num_volumes_read'
        ) if status_str == 'reading'
      end

      data_dir = File.join(site.source, '_data')
      FileUtils.mkdir_p(data_dir)

      File.write(data_file, JSON.pretty_generate(all_manga))
      Jekyll.logger.info 'MAL Manga:', "Synced #{all_manga.size} total manga to mal_manga_list.json"

      File.write(File.join(data_dir, 'mal_currently_reading_manga.json'), JSON.pretty_generate(currently_reading))
      Jekyll.logger.info 'MAL Manga:', "Synced #{currently_reading.size} currently reading to mal_currently_reading_manga.json"
    end

    private

    def fetch_all
      all_entries = []
      offset = 0

      loop do
        url = "https://myanimelist.net/mangalist/#{MAL_USERNAME}/load.json?offset=#{offset}&status=7"
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 20

        req = Net::HTTP::Get.new(uri.request_uri)
        req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        req['Accept'] = 'application/json, text/javascript, */*'

        res = http.request(req)
        unless res.is_a?(Net::HTTPSuccess)
          Jekyll.logger.warn 'MAL Manga:', "HTTP #{res.code} at offset #{offset} — stopping pagination"
          break
        end

        page = JSON.parse(res.body)
        break if page.empty?

        all_entries.concat(page)
        break if page.size < PAGE_SIZE

        offset += PAGE_SIZE
        sleep 0.5
      end

      all_entries
    rescue StandardError => e
      Jekyll.logger.warn 'MAL Manga API error:', e.message
      nil
    end

    # Convert MAL's "MM-DD-YY" date strings to "YYYY-MM-DD".
    def parse_date(str)
      return nil if str.nil? || str.strip.empty?
      Date.strptime(str.strip, '%m-%d-%y').strftime('%Y-%m-%d')
    rescue ArgumentError
      nil
    end

    # Reconstruct a canonical large-image URL from the CDN thumbnail URL.
    # CDN:       https://cdn.myanimelist.net/r/192x272/images/manga/3/269402.jpg?s=abc
    # Canonical: https://myanimelist.net/images/manga/3/269402l.jpg
    def canonical_cover_url(cdn_url, type)
      return nil unless cdn_url
      match = cdn_url.match(%r{/(images/#{type}/[^?]+)})
      return cdn_url unless match
      path = match[1].sub(/(\.\w+)\z/, 'l\1')
      "https://myanimelist.net/#{path}"
    rescue StandardError
      cdn_url
    end

    def download_cover(url, basename, images_dir)
      return nil unless url

      filepath = File.join(images_dir, "#{basename}.webp")
      unless File.exist?(filepath)
        fetched = URI.open(url)
        image = MiniMagick::Image.read(fetched)
        image.format 'webp'
        image.write filepath
      end

      File.join('assets', 'images', 'mal', "#{basename}.webp")
    rescue StandardError => e
      Jekyll.logger.warn "MAL Manga image error for #{url}:", e.message
      nil
    end
  end
end
