# Uploaded media for club records (map images, course maps, event results
# files), stored on the shared data volume as
#   <dataFolder>/<club_id>/<dir>/<id>.<ext>
# with generated thumbnails at <id>_<WxH>.png (plus doubled HiDPI sizes) and a
# normalized <id>_image.jpg. Ids are cast to Integer and thumbnails validated
# against the per-type allowlist so no path component ever comes from raw user
# input.
class MediaStore
  TYPES = {
    'Map' => { dir: 'maps', thumbnail_sizes: %w[400x600 50x50 60x60], allowed_extensions: %w[jpg jpeg gif png] },
    'Course' => { dir: 'courses', thumbnail_sizes: %w[100x150 600x600], allowed_extensions: %w[jpg jpeg gif png pdf] },
    'Event' => { dir: 'events', thumbnail_sizes: [], allowed_extensions: %w[xml] }
  }.freeze

  def self.double_size(size)
    size.split('x').map { |dimension| Integer(dimension) * 2 }.join('x')
  end

  # Bundled fallback images served when a record has no uploaded media
  def self.default_image_path(type)
    raise ArgumentError, "unknown media type #{type}" unless TYPES.key?(type)

    Rails.root.join('public', 'clubsite-defaults', "#{type}.png")
  end

  def initialize(club_id, type)
    raise ArgumentError, "unknown media type #{type}" unless TYPES.key?(type)

    @club_id = Integer(club_id)
    @type = type
    @config = TYPES[type]
  end

  attr_reader :type

  # Absolute path of the original uploaded file, or nil
  def file_path(id)
    matches = Dir.glob(folder.join("#{Integer(id)}.*").to_s)
    raise "Found more than one matching file" if matches.length > 1

    matches.first
  end

  # Absolute path of a generated thumbnail ('image' or a WxH size), or nil
  def thumbnail_path(id, thumbnail)
    return nil unless valid_thumbnail?(thumbnail)

    extension = thumbnail == 'image' ? 'jpg' : 'png'
    path = folder.join("#{Integer(id)}_#{thumbnail}.#{extension}")
    path.file? ? path.to_s : nil
  end

  def exists?(id, thumbnail = nil)
    if thumbnail
      thumbnail_path(id, thumbnail).present?
    else
      file_path(id).present?
    end
  end

  def valid_thumbnail?(thumbnail)
    thumbnail == 'image' || all_thumbnail_sizes.include?(thumbnail)
  end

  # Configured sizes plus their doubled HiDPI variants
  def all_thumbnail_sizes
    @config[:thumbnail_sizes].flat_map { |size| [size, self.class.double_size(size)] }.uniq
  end

  def allowed_extensions
    @config[:allowed_extensions]
  end

  def folder
    Pathname.new(Settings.dataFolder).join(@club_id.to_s, @config[:dir])
  end

  # Stores an uploaded file as <id>.<ext> and generates derived images,
  # replacing any previous upload. Returns an error message string on
  # rejection, nil on success (matching the legacy component's contract).
  def store(id, upload)
    return 'No file to create was provided.' if upload.blank?

    extension = File.extname(upload.original_filename).delete_prefix('.').downcase
    unless allowed_extensions.include?(extension)
      return "The uploaded file format is not allowed. Please use one of #{allowed_extensions.join(',')}"
    end

    delete(id)
    FileUtils.mkdir_p(folder)
    File.open(folder.join("#{Integer(id)}.#{extension}"), 'wb') do |file|
      IO.copy_stream(upload.tempfile, file)
    end
    build_images(id)
    nil
  end

  # Removes the original upload and every derived image
  def delete(id)
    id = Integer(id)
    original = file_path(id)
    FileUtils.rm_f(original) if original
    Dir.glob(folder.join("#{id}_*.{jpg,png}").to_s).each { |path| FileUtils.rm_f(path) }
  end

  # Builds the normalized full-size <id>_image.jpg (PDF pages appended into
  # one tall image) and a png thumbnail per configured size, generated from
  # the normalized image.
  IMAGE_EXTENSIONS = %w[jpg jpeg gif png pdf].freeze

  def build_images(id)
    id = Integer(id)
    source = file_path(id)
    return if source.nil?
    # Non-image uploads (event results XML) have no derived images
    return unless IMAGE_EXTENSIONS.include?(File.extname(source).delete_prefix('.').downcase)

    image_path = folder.join("#{id}_image.jpg").to_s
    create_image(source, image_path, nil)
    all_thumbnail_sizes.each do |size|
      create_image(image_path, folder.join("#{id}_#{size}.png").to_s, size)
    end
  end

  # Cropped thumbnail (and its HiDPI double) taken from the original, used for
  # map banners. Position 'random' picks a random crop window.
  def create_cropped_thumbnail(id, size, position = 'random')
    id = Integer(id)
    source = file_path(id)
    return if source.nil?

    doubled = self.class.double_size(size)
    image = MiniMagick::Image.open(source)
    crop_width, crop_height = doubled.split('x').map(&:to_i)
    if position == 'random'
      offset_x = rand([image.width - crop_width, 0].max + 1)
      offset_y = rand([image.height - crop_height, 0].max + 1)
    else
      offset_x = image.width / 2
      offset_y = image.height / 2
    end

    { size => folder.join("#{id}_#{size}.png").to_s,
      doubled => folder.join("#{id}_#{doubled}.png").to_s }.each do |target_size, destination|
      FileUtils.rm_f(destination)
      MiniMagick.convert do |convert|
        # The source must be read before image operators are applied
        convert << source
        convert.crop("#{doubled}+#{offset_x}+#{offset_y}")
        convert.strip
        convert.interlace('Plane')
        convert.gaussian_blur('0.05')
        convert.quality('85%')
        convert.resize(target_size)
        convert << '+repage'
        convert << destination
      end
    end
  end

  private

  # Port of the legacy conversion pipeline: white background for transparency,
  # progressive jpg, PDFs rendered at high density with all pages appended.
  # All arguments go through MiniMagick's argv API; nothing touches a shell.
  def create_image(source, destination, size)
    FileUtils.rm_f(destination)
    pdf = File.extname(source).casecmp?('.pdf')
    MiniMagick.convert do |convert|
      # Settings that must precede reading the source
      convert.background('white')
      convert.quality('85%')
      if pdf
        convert.density(288)
        convert.colorspace('RGB')
      end
      convert << source
      # Image operators apply once the source has been read
      convert.strip
      convert.interlace('Plane')
      convert.gaussian_blur('0.05')
      convert.alpha('remove')
      if pdf
        convert << '-append'
      else
        convert.resize("#{size}>") if size
      end
      convert << destination
    end
  end
end
