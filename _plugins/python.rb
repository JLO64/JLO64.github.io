module Jekyll
  class ReplacePostMdLinks < Generator
    safe true
    priority :highest

    def generate(site)
      site.posts.docs.each do |post|
        original_content = post.content
        modified_content = replace_links(post.content)
        post.content = modified_content

        # Print before and after content to the console
        # puts "Original Content for #{post.data['title']}:\n\n#{original_content}\n\n"
        # puts "Modified Content for #{post.data['title']}:\n\n#{modified_content}\n\n"
      end
    end

    def replace_links(text)
      text.gsub(/(\[.*?\])\((.*?)\)/) do |match|
        link_text = Regexp.last_match(1)
        link = Regexp.last_match(2)
        if !link.include?('/') && !link.include?('#')
          link = link.sub(/\.md$/, '')  # remove .md extension
          "#{link_text}({% post_url #{link} %})"
        else
          match
        end
      end
    end    
  end
end
