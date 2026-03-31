#!/usr/bin/env ruby
# Proof-of-concept: fetch JLO64's MAL anime list via the public load.json
# endpoint (no API token required) and write output matching the schema of
# _data/mal_anime_list.json.
#
# Usage:
#   ruby _scripts/mal_anime_scrape_poc.rb
#
# Outputs:
#   _data/mal_anime_list_poc.json       — full list (compare with mal_anime_list.json)
#   _data/mal_currently_watching_poc.json — watching subset

require 'net/http'
require 'uri'
require 'json'
require 'date'

USERNAME  = 'JLO64'
PAGE_SIZE = 300

STATUS_MAP = {
  1 => 'watching',
  2 => 'completed',
  3 => 'on_hold',
  4 => 'dropped',
  6 => 'plan_to_watch'
}.freeze

# Fetch all pages from the load.json endpoint (status=7 means "all statuses").
def fetch_all
  all_entries = []
  offset = 0

  loop do
    url = "https://myanimelist.net/animelist/#{USERNAME}/load.json?offset=#{offset}&status=7"
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
      warn "HTTP #{res.code} at offset #{offset} — stopping pagination"
      break
    end

    page = JSON.parse(res.body)
    break if page.empty?

    all_entries.concat(page)
    puts "  fetched #{page.size} entries (offset #{offset}, total so far: #{all_entries.size})"

    break if page.size < PAGE_SIZE

    offset += PAGE_SIZE
    sleep 0.5 # be polite
  end

  all_entries
rescue StandardError => e
  warn "Fetch error: #{e.message}"
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
# CDN:       https://cdn.myanimelist.net/r/192x272/images/anime/5/46489.jpg?s=abc
# Canonical: https://myanimelist.net/images/anime/5/46489l.jpg
def canonical_cover_url(cdn_url)
  return nil unless cdn_url

  match = cdn_url.match(%r{/(images/anime/[^?]+)})
  return cdn_url unless match

  path = match[1]                        # e.g. images/anime/5/46489.jpg
  path = path.sub(/(\.\w+)\z/, 'l\1')   # → images/anime/5/46489l.jpg
  "https://myanimelist.net/#{path}"
rescue StandardError
  cdn_url
end

# ── Main ──────────────────────────────────────────────────────────────────────

puts "Fetching anime list for #{USERNAME}..."
raw = fetch_all

if raw.nil? || raw.empty?
  warn "No data returned — aborting."
  exit 1
end

puts "Processing #{raw.size} entries..."

all_anime         = []
currently_watching = []

raw.each do |entry|
  anime_id   = entry['anime_id']
  status_int = entry['status']
  status_str = STATUS_MAP[status_int] || "unknown_#{status_int}"

  finish_date  = parse_date(entry['finish_date_string'])
  start_date   = parse_date(entry['start_date_string'])
  created_date = entry['created_at']&.then { |t| Time.at(t).strftime('%Y-%m-%d') rescue nil }
  sort_date    = finish_date || start_date || created_date || '0000-00-00'

  cover_url  = canonical_cover_url(entry['anime_image_path'])
  cover_path = "assets/images/mal/mal_anime_#{anime_id}.webp"

  title = entry['title_localized'].to_s.strip
  title = entry['anime_title'].to_s.strip if title.empty?

  record = {
    'id'                   => anime_id,
    'title'                => title,
    'status'               => status_str,
    'cover_url'            => cover_url,
    'cover_filepath'       => cover_path,
    'score'                => entry['score'],
    'num_episodes'         => entry['anime_num_episodes'],
    'num_episodes_watched' => entry['num_watched_episodes'],
    'finish_date'          => finish_date,
    'start_date'           => start_date,
    'sort_date'            => sort_date
  }

  all_anime << record
  currently_watching << record.slice(
    'id', 'title', 'cover_url', 'cover_filepath', 'score',
    'num_episodes', 'num_episodes_watched'
  ) if status_str == 'watching'
end

data_dir = File.join(__dir__, '..', '_data')

full_path     = File.join(data_dir, 'mal_anime_list_poc.json')
watching_path = File.join(data_dir, 'mal_currently_watching_poc.json')

File.write(full_path, JSON.pretty_generate(all_anime))
puts "Wrote #{all_anime.size} entries → #{full_path}"

File.write(watching_path, JSON.pretty_generate(currently_watching))
puts "Wrote #{currently_watching.size} currently-watching → #{watching_path}"
