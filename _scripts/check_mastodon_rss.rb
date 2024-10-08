require 'rss'
require 'open-uri'
require 'yaml'
require 'nokogiri'

rss_url = 'https://fosstodon.org/@JLO64.rss'
rss_content = URI.open(rss_url).read
rss = RSS::Parser.parse(rss_content, false)
first_item = rss.items.first
most_recent_mastodon_post_link = first_item.link

# download the homepage then find the <a> with id 'mastodon-link' and extract the href
homepage = URI.open('https://www.julianlopez.net/').read
doc = Nokogiri::HTML(homepage)
stored_most_recent_mastodon_post_link = doc.at_css('#mastodon-post-link')['href']
# puts stored_most_recent_mastodon_post_link

# most_recent_mastodon_post = YAML.load_file('_data/most_recent_mastodon_post.yml', permitted_classes: [Time])
# stored_most_recent_mastodon_post_link = most_recent_mastodon_post['link']

if most_recent_mastodon_post_link != stored_most_recent_mastodon_post_link
    puts "true"
else
    puts "false"
    # exit 1
end