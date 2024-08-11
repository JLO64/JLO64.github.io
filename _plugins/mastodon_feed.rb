# _plugins/mastodon_feed.rb
require 'rss'
require 'open-uri'
require 'yaml'

module Jekyll
  class MastodonFeedGenerator < Generator
    safe true

    def generate(site)
      rss_url = 'https://fosstodon.org/@JLO64.rss' # Replace with your Mastodon RSS feed URL
      rss_content = URI.open(rss_url).read
      rss = RSS::Parser.parse(rss_content, false)

      first_item = rss.items.first
      mastodon_post = {
        'title' => first_item.title,
        'link' => first_item.link,
        'description' => first_item.description,
        'pubDate' => first_item.pubDate
      }

      File.open('_data/most_recent_mastodon_post.yml', 'w') do |file|
        file.write(mastodon_post.to_yaml)
      end
    end
  end
end