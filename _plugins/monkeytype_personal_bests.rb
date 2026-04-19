require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

module Jekyll
  # Generator plugin to fetch Monkeytype personal bests (time mode, 30s)
  class MonkeytypePersonalBestsGenerator < Generator
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

      # Expect API key in MONKEYTYPE_API_KEY
      api_key = ENV['MONKEYTYPE_API_KEY']
      return unless api_key && !api_key.empty?

      # Prepare HTTP request
      endpoint = 'https://api.monkeytype.com/users/personalBests'
      uri = URI.parse("#{endpoint}?mode=time")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "ApeKey #{api_key}"

      # Execute and parse response, silently skip on failure
      begin
        response = http.request(request)
        return unless response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
      rescue StandardError => e
        Jekyll.logger.warn "Monkeytype API error:", e.message
        return
      end

      # Extract only the 30-second personal bests (raw API response as-is)
      data = result.dig("data", "30")

      # Convert timestamp to formatted date string (MM/DD/YYYY)
      data.each do |record|
        if record['timestamp']
          timestamp_seconds = record['timestamp'] / 1000
          record['timestamp'] = Time.at(timestamp_seconds).strftime('%m/%d/%Y')
        end
      end

      # Write result to _data/monkeytype_personal_bests.json
      data_dir = File.join(site.source, '_data')
      FileUtils.mkdir_p(data_dir) unless Dir.exist?(data_dir)
      file_path = File.join(data_dir, 'monkeytype_personal_bests.json')
      File.open(file_path, 'w') do |f|
        f.write(JSON.pretty_generate(data))
      end
    end
  end
end
