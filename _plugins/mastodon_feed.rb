# _plugins/mastodon_feed.rb
require 'rss'
require 'open-uri'
require 'yaml'
require 'open-uri'
require 'mini_magick'
# require 'nokogiri'

module Jekyll
  class MastodonFeedGenerator < Generator
    safe true

    def generate(site)
      rss_url = 'https://fosstodon.org/@JLO64.rss' # Replace with your Mastodon RSS feed URL
      rss_content = URI.open(rss_url).read
      rss = RSS::Parser.parse(rss_content, false)

      mastodon_profile_image = rss.channel.image.url
      File.open('assets/images/mastodon_profile_image.jpeg', 'wb') do |file|
        file.write(URI.open(mastodon_profile_image).read)
      end
      # convert this image to webp and resize it to 200x200
      mastodon_profile_image_converted = MiniMagick::Image.open('assets/images/mastodon_profile_image.jpeg')
      mastodon_profile_image_converted.format('webp')
      mastodon_profile_image_converted.resize('120x120')
      mastodon_profile_image_converted.write('assets/images/mastodon_profile_image.webp')

      first_item = rss.items.first
      mastodon_post = {
        'link' => first_item.link,
        'description' => first_item.description,
        'pubDate' => first_item.pubDate
      }

      # for each <image> within first_item, download the image
      # list_of_images = first_item.media
      # print(list_of_images)
      File.open('_data/most_recent_mastodon_post.yml', 'w') do |file|
        file.write(mastodon_post.to_yaml)
      end
    end
  end
end