require 'mini_magick'
require 'fileutils'

module Jekyll
  # Generator plugin to create 480px-wide WebP thumbnails for post images.
  # Scans assets/images/posts/**/* and writes thumbnails to a thumbnails/
  # subdirectory alongside each original. Skips images that already have a
  # thumbnail. Commit the thumbnails/ directories to git.
  class PostImageThumbnailGenerator < Generator
    safe true

    SUPPORTED_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp].freeze

    def generate(site)
      images_dir = File.join(site.source, 'assets', 'images', 'posts')
      return unless Dir.exist?(images_dir)

      generated = 0
      skipped = 0

      Dir.glob(File.join(images_dir, '**', '*')).sort.each do |source_path|
        next unless File.file?(source_path)
        next unless SUPPORTED_EXTENSIONS.include?(File.extname(source_path).downcase)
        next if source_path.split(File::SEPARATOR).include?('thumbnails')

        dir = File.dirname(source_path)
        basename = File.basename(source_path, File.extname(source_path))
        thumbnails_dir = File.join(dir, 'thumbnails')
        thumbnail_path = File.join(thumbnails_dir, "#{basename}.webp")

        if File.exist?(thumbnail_path)
          skipped += 1
          next
        end

        begin
          FileUtils.mkdir_p(thumbnails_dir)
          image = MiniMagick::Image.open(source_path)
          image.resize '480x>' # shrink to max 480px wide, preserve aspect ratio
          image.format 'webp'
          image.write thumbnail_path

          # Also copy to _site/ — generators run after static files are copied,
          # so newly created thumbnails must be written to the destination manually.
          relative_path = thumbnail_path.sub(site.source + File::SEPARATOR, '')
          dest_path = File.join(site.dest, relative_path)
          FileUtils.mkdir_p(File.dirname(dest_path))
          FileUtils.cp(thumbnail_path, dest_path)

          generated += 1
          Jekyll.logger.info "Post thumbnails:", "Generated #{File.join('thumbnails', "#{basename}.webp")} in #{dir.sub(site.source + '/', '')}"
        rescue StandardError => e
          Jekyll.logger.warn "Post thumbnails:", "Error processing #{source_path}: #{e.message}"
        end
      end

      Jekyll.logger.info "Post thumbnails:", "Done — #{generated} generated, #{skipped} already exist"
    end
  end
end
