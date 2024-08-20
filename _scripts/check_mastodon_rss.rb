require 'rss'
require 'open-uri'
require 'yaml'

rss_url = 'https://fosstodon.org/@JLO64.rss'
rss_content = URI.open(rss_url).read
rss = RSS::Parser.parse(rss_content, false)
first_item = rss.items.first
most_recent_mastodon_post_link = first_item.link

most_recent_mastodon_post = YAML.load_file('_data/most_recent_mastodon_post.yml', permitted_classes: [Time])
stored_most_recent_mastodon_post_link = most_recent_mastodon_post['link']

if most_recent_mastodon_post_link != stored_most_recent_mastodon_post_link
    puts "New post detected: #{most_recent_mastodon_post_link}"
    # have this script close with an error
else
    puts "No new post detected"
    exit 1
end