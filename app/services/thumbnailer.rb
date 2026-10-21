require 'image_processing/mini_magick'

# Generates jpg thumbnails from uploaded files (images and PDFs) with
# ImageMagick, via the image_processing gem.
class Thumbnailer
  class MissingDependencyError < StandardError; end

  # Resizes the file at source_path into a jpg at destination_path, capped at
  # `size` pixels wide. Aspect ratio is preserved and images narrower than the
  # cap are never enlarged (ImageMagick's `-resize <size>>` semantics). For
  # multi-page/multi-frame sources (PDFs, animated gifs) only the first
  # page/frame is used.
  def self.resize(source_path, destination_path, size)
    ensure_available!

    width = Integer(size)
    ImageProcessing::MiniMagick
      .source(source_path)
      .loader(page: 0)
      .resize_to_limit(width, nil)
      .append('-background', 'white')
      .append('-alpha', 'remove')
      .append('-strip')
      .append('-interlace', 'Plane')
      .saver(quality: 85)
      .convert('jpg')
      .call(destination: destination_path)
  end

  # Whether the ImageMagick command line tools are installed
  def self.available?
    MiniMagick.cli_version.present?
  rescue StandardError
    false
  end

  def self.ensure_available!
    return if available?

    raise MissingDependencyError,
          'ImageMagick is not installed: thumbnails cannot be generated. ' \
          'Install the imagemagick package (and ghostscript for PDF support).'
  end
end
