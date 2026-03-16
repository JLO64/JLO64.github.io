#!/usr/bin/env ruby
# One-time script to authenticate with MyAnimeList OAuth2 and save tokens to .env
#
# Prerequisites:
#   1. In your MAL API app settings, set the redirect URL to: http://localhost:8080
#      (Visit: https://myanimelist.net/apiconfig and edit your app)
#   2. MAL_Client_ID and MAL_Client_Secret must be in your .env file
#
# Usage:
#   ruby _scripts/mal_auth.rb

require 'net/http'
require 'uri'
require 'json'
require 'securerandom'
require 'webrick'

ENV_PATH = File.expand_path('../../.env', __FILE__)

def load_env
  env = {}
  return env unless File.exist?(ENV_PATH)
  File.foreach(ENV_PATH) do |line|
    next if line.strip.start_with?('#') || line.strip.empty?
    key, value = line.strip.split('=', 2)
    env[key] = value
  end
  env
end

def write_env_keys(updates)
  lines = File.exist?(ENV_PATH) ? File.readlines(ENV_PATH) : []
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
  File.write(ENV_PATH, lines.join)
end

env           = load_env
client_id     = env['MAL_Client_ID']     or abort("ERROR: MAL_Client_ID not found in .env")
client_secret = env['MAL_Client_Secret'] or abort("ERROR: MAL_Client_Secret not found in .env")

# MAL uses PKCE with plain method: code_challenge == code_verifier
code_verifier = SecureRandom.urlsafe_base64(96)
state         = SecureRandom.hex(8)

auth_params = URI.encode_www_form(
  response_type:  'code',
  client_id:      client_id,
  code_challenge: code_verifier,
  state:          state
)
auth_url = "https://myanimelist.net/v1/oauth2/authorize?#{auth_params}"

puts "=" * 64
puts "  MyAnimeList OAuth Setup"
puts "=" * 64
puts
puts "PREREQUISITE: Your MAL app redirect URL must be set to:"
puts "  http://localhost:8080"
puts "  (Edit at: https://myanimelist.net/apiconfig)"
puts
puts "Step 1: Open this URL in your browser:"
puts
puts "  #{auth_url}"
puts
puts "Step 2: Click 'Allow' to authorize."
puts
puts "Waiting for callback on http://localhost:8080 ..."
puts "(Ctrl+C to cancel)"

auth_code = nil

server = WEBrick::HTTPServer.new(
  Port:       8080,
  Logger:     WEBrick::Log.new(IO::NULL),
  AccessLog:  []
)

server.mount_proc('/') do |req, res|
  auth_code = req.query['code']
  res['Content-Type'] = 'text/html; charset=utf-8'
  res.body = <<~HTML
    <!DOCTYPE html>
    <html>
      <body style="font-family:sans-serif;text-align:center;margin-top:4rem">
        <h2>&#x2705; Authorization successful!</h2>
        <p>You can close this tab and return to the terminal.</p>
      </body>
    </html>
  HTML
  server.shutdown
end

trap('INT') { server.shutdown }
server.start

abort("\nNo authorization code received. Did you allow access?") unless auth_code

puts "\nReceived authorization code. Exchanging for tokens..."

uri  = URI.parse('https://myanimelist.net/v1/oauth2/token')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

req = Net::HTTP::Post.new(uri.request_uri)
req['Content-Type'] = 'application/x-www-form-urlencoded'
req.body = URI.encode_www_form(
  client_id:     client_id,
  client_secret: client_secret,
  code:          auth_code,
  code_verifier: code_verifier,
  grant_type:    'authorization_code'
)

res = http.request(req)
unless res.is_a?(Net::HTTPSuccess)
  abort("Token exchange failed (HTTP #{res.code}):\n#{res.body}")
end

result        = JSON.parse(res.body)
access_token  = result['access_token']  or abort("No access_token in response: #{res.body}")
refresh_token = result['refresh_token'] or abort("No refresh_token in response: #{res.body}")
expires_in    = result['expires_in'].to_i
expires_at    = Time.now.to_i + expires_in

write_env_keys(
  'MAL_ACCESS_TOKEN'     => access_token,
  'MAL_REFRESH_TOKEN'    => refresh_token,
  'MAL_TOKEN_EXPIRES_AT' => expires_at.to_s
)

puts
puts "=" * 64
puts "  Done!"
puts "=" * 64
puts
puts "Tokens saved to .env"
puts "  Access token expires: #{Time.at(expires_at).strftime('%Y-%m-%d %H:%M %Z')}"
puts
puts "Next step: run 'bundle exec jekyll build' twice to sync your anime data."
