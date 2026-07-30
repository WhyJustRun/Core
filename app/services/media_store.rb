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
end
