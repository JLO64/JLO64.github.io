# _plugins/mastodon_feed.rb
require 'rss'
require 'open-uri'
require 'yaml'
require 'open-uri'
require 'mini_magick'
require 'nokogiri'

module Jekyll
  class MastodonFeedGenerator < Generator
    safe true

    def generate(site)
      rss_url = 'https://fosstodon.org/@JLO64.rss' # Replace with your Mastodon RSS feed URL
      rss_content = URI.open(rss_url).read
      rss = RSS::Parser.parse(rss_content, false)

      mastodon_profile_image_url = rss.channel.image.url
      mastodon_profile_image_path = 'assets/images/mastodon_profile_image.jpeg'
      mastodon_profile_image_webp_path = 'assets/images/mastodon_profile_image.webp'

      first_item = rss.items.first
      mastodon_post = {
        'link' => first_item.link,
        'description' => first_item.description,
        'pubDate' => first_item.pubDate
      }

      # create an array of all the <media> within the first <item> inside rss_content
      list_of_image_urls = []
      nokogiri_rss_xml = Nokogiri::XML(rss_content)
      nokogiri_rss_xml_first_item = nokogiri_rss_xml.xpath('//channel/item[1]')
      nokogiri_rss_xml_first_item.xpath('.//media:content').each do |media_content|
        list_of_image_urls.push(media_content['url'])
      end
      mastodon_post['number_of_images'] = list_of_image_urls.length
      list_of_image_filenames = []
      for i in 0..list_of_image_urls.length-1
        filename_string = "mastodon_image_#{i}.webp"
        list_of_image_filenames.push(filename_string)
      end
      mastodon_post['image_filenames'] = list_of_image_filenames
      



      # for each <image> within first_item, download the image
      # list_of_images = first_item.media
      # print(list_of_images)
      File.open('_data/most_recent_mastodon_post.yml', 'w') do |file|
        file.write(mastodon_post.to_yaml)
      end


      unless File.exist?(mastodon_profile_image_webp_path)
        File.open(mastodon_profile_image_path, 'wb') do |file|
          file.write(URI.open(mastodon_profile_image_url).read)
        end

        # Convert this image to webp and resize it to 120x120
        mastodon_profile_image_converted = MiniMagick::Image.open(mastodon_profile_image_path)
        mastodon_profile_image_converted.format('webp')
        mastodon_profile_image_converted.resize('120x120')
        mastodon_profile_image_converted.write(mastodon_profile_image_webp_path)

        
        # download all images from the list_of_images and append their paths to the mastodon_post
        list_of_images.each_with_index do |image_url, index|
          mastodon_image_path = "assets/images/mastodon_image_#{index}.jpeg"
          mastodon_image_webp_path = "assets/images/mastodon_image_#{index}.webp"
          File.open(mastodon_image_path, 'wb') do |file|
            file.write(URI.open(image_url).read)
          end
          mastodon_image_converted = MiniMagick::Image.open(mastodon_image_path)
          mastodon_image_converted.format('webp')
          mastodon_image_converted.resize('200x200')
          mastodon_image_converted.write(mastodon_image_webp_path)
        end

        # Hook to regenerate the site after the generator runs
        Jekyll::Hooks.register :site, :post_write do |site|
          system("jekyll build")
        end
      end

    end
  end

end