#!/usr/bin/env ruby
# Proof-of-concept: fetch JLO64's MAL manga list via the public load.json
# endpoint (no API token required) and write output matching the schema of
# _data/mal_manga_list.json.
#
# Usage:
#   ruby _scripts/mal_manga_scrape_poc.rb
#
# Outputs:
#   _data/mal_manga_list_poc.json          — full list (compare with mal_manga_list.json)
#   _data/mal_currently_reading_manga_poc.json — reading subset

require 'net/http'
require 'uri'
require 'json'
require 'date'

USERNAME = 'JLO64'
PAGE_SIZE = 300

STATUS_MAP = {
  1 => 'reading',
  2 => 'completed',
  3 => 'on_hold',
  4 => 'dropped',
  6 => 'plan_to_read'
}.freeze

# Fetch all pages from the load.json endpoint (status=7 means "all statuses").
def fetch_all
  all_entries = []
  offset = 0

  loop do
    url = "https://myanimelist.net/mangalist/#{USERNAME}/load.json?offset=#{offset}&status=7"
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 20

    req = Net::HTTP::Get.new(uri.request_uri)
    # A browser-like User-Agent avoids bot-blocking.
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
# CDN:       https://cdn.myanimelist.net/r/192x272/images/manga/3/269402.jpg?s=abc
# Canonical: https://myanimelist.net/images/manga/3/269402l.jpg
def canonical_cover_url(cdn_url)
  return nil unless cdn_url

  # Strip resize segment (/r/WxH/) and query string, then add 'l' suffix.
  match = cdn_url.match(%r{/(images/manga/[^?]+)})
  return cdn_url unless match

  path = match[1]                             # e.g. images/manga/3/269402.jpg
  path = path.sub(/(\.\w+)\z/, 'l\1')        # → images/manga/3/269402l.jpg
  "https://myanimelist.net/#{path}"
rescue StandardError
  cdn_url
end

# ── Main ──────────────────────────────────────────────────────────────────────

puts "Fetching manga list for #{USERNAME}..."
raw = fetch_all

if raw.nil? || raw.empty?
  warn "No data returned — aborting."
  exit 1
end

puts "Processing #{raw.size} entries..."

all_manga         = []
currently_reading = []

raw.each do |entry|
  manga_id    = entry['manga_id']
  status_int  = entry['status']
  status_str  = STATUS_MAP[status_int] || "unknown_#{status_int}"

  finish_date = parse_date(entry['finish_date_string'])
  start_date  = parse_date(entry['start_date_string'])
  # created_at is an epoch integer in load.json; use it as last-resort sort key.
  created_date = entry['created_at']&.then { |t| Time.at(t).strftime('%Y-%m-%d') rescue nil }
  sort_date    = finish_date || start_date || created_date || '0000-00-00'

  cover_url  = canonical_cover_url(entry['manga_image_path'])
  cover_path = "assets/images/mal/mal_manga_#{manga_id}.webp"

  title = entry['title_localized'].to_s.strip
  title = entry['manga_title'].to_s.strip if title.empty?

  record = {
    'id'                => manga_id,
    'title'             => title,
    'status'            => status_str,
    'cover_url'         => cover_url,
    'cover_filepath'    => cover_path,
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

data_dir = File.join(__dir__, '..', '_data')

full_path    = File.join(data_dir, 'mal_manga_list_poc.json')
reading_path = File.join(data_dir, 'mal_currently_reading_manga_poc.json')

File.write(full_path, JSON.pretty_generate(all_manga))
puts "Wrote #{all_manga.size} entries → #{full_path}"

File.write(reading_path, JSON.pretty_generate(currently_reading))
puts "Wrote #{currently_reading.size} currently-reading → #{reading_path}"
