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
      rss_url = 'https://gotosocial.julianlopez.net/@jlo64/feed.rss' # Replace with your Mastodon RSS feed URL
      rss_content = URI.open(rss_url).read
      rss = RSS::Parser.parse(rss_content, false)

      mastodon_profile_image_url = rss.channel.image.url
      mastodon_profile_image_path = 'assets/images/mastodon_profile_image.jpeg'
      mastodon_profile_image_webp_path = 'assets/images/mastodon_profile_image.webp'

      first_item = rss.items.first
      mastodon_post = {
        'link' => first_item.link,
        # 'description' => first_item.description.gsub(/^.*?:\s+"(.*?)"\s*$/, '\1'),
        # 'description' => first_item.content_encoded,
        'pubDate' => first_item.pubDate
      }

      # create an array of all the <enclosure> within the first <item> inside rss_content
      list_of_image_urls = []
      nokogiri_rss_xml = Nokogiri::XML(rss_content)
      nokogiri_rss_xml_first_item = nokogiri_rss_xml.xpath('//channel/item[1]')
      nokogiri_rss_xml_first_item.xpath('.//enclosure').each do |enclosure|
        list_of_image_urls.push(enclosure['url'])
        # print(enclosure['url'])
      end
      mastodon_post['number_of_images'] = list_of_image_urls.length
      list_of_image_filenames = []
      for i in 0..list_of_image_urls.length-1
        filename_string = "mastodon_image_#{i}" + ".webp"
        list_of_image_filenames.push(filename_string)
      end
      mastodon_post['image_filenames'] = list_of_image_filenames
      
      first_item_content = first_item.content_encoded
      first_item_content_html = Nokogiri::HTML(first_item_content)
      # save the content inside the <body> tag of the first_item
      mastodon_post['description'] = first_item_content_html.xpath('//body').inner_html



      # for each <image> within first_item, download the image
      # list_of_images = first_item.media
      # print(list_of_images)
      File.open('_data/most_recent_mastodon_post.yml', 'w') do |file|
        file.write(mastodon_post.to_yaml)
      end

      if File.exist?(mastodon_profile_image_webp_path)
        file_age = File.mtime(mastodon_profile_image_webp_path)
        file_age_in_seconds = Time.now - file_age
        if file_age_in_seconds > 86400
          puts "Profile image is more than 24 hours old, downloading a new one"
          download_profile_image(
            mastodon_profile_image_path,
            mastodon_profile_image_webp_path,
            mastodon_profile_image_url
          )
        end
      else
        download_profile_image(
          mastodon_profile_image_path,
          mastodon_profile_image_webp_path,
          mastodon_profile_image_url
        )
      end

      if list_of_image_urls.length > 0
        puts "There are images in the post"
        list_of_image_urls.each_with_index do |image_url, index|
          image_webp_path = "assets/images/mastodon_image_#{index}" + ".webp"
          if File.exist?(image_webp_path)
            puts "Image already exists"
            file_age = File.mtime(image_webp_path)
            file_age_in_seconds = Time.now - file_age
            if file_age_in_seconds > 86400
              puts "Image is more than 24 hours old, downloading a new one"
              download_images(list_of_image_urls)
            end
          else
            puts "Image does not exist"
            download_images(list_of_image_urls)
          end
        end
      end
    end

    def download_profile_image(mastodon_profile_image_path, mastodon_profile_image_webp_path, mastodon_profile_image_url)
      File.open(mastodon_profile_image_path, 'wb') do |file|
        file.write(URI.open(mastodon_profile_image_url).read)
      end
      mastodon_profile_image_converted = MiniMagick::Image.open(mastodon_profile_image_path)
      mastodon_profile_image_converted.format('webp')
      mastodon_profile_image_converted.resize('120x120')
      mastodon_profile_image_converted.write(mastodon_profile_image_webp_path)

      Jekyll::Hooks.register :site, :post_write do |site|
        system("jekyll build")
      end
    end

    def download_images(list_of_image_urls)
      list_of_image_urls.each_with_index do |image_url, index|
        mastodon_image_path = "assets/images/mastodon_image_#{index}.jpeg"
        mastodon_image_webp_path = "assets/images/mastodon_image_#{index}" + ".webp"
        File.open(mastodon_image_path, 'wb') do |file|
          file.write(URI.open(image_url).read)
        end
        mastodon_image_converted = MiniMagick::Image.open(mastodon_image_path)
        mastodon_image_converted.format('webp')
        mastodon_image_converted.resize('400x400')
        mastodon_image_converted.write(mastodon_image_webp_path)
      end
      Jekyll::Hooks.register :site, :post_write do |site|
        system("jekyll build")
      end
    end

  end

end
