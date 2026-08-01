require 'digest/md5'

# Club branding assets (header image, logo, custom stylesheet) stored on the
# shared data volume as <dataFolder>/<club_id>/<key>.<extension> with jpg
# thumbnails alongside.
class Resource < ApplicationRecord
  # Raised when an upload is rejected (missing file, disallowed extension)
  class InvalidUpload < StandardError; end

  THUMBNAILABLE_EXTENSIONS = %w[jpg jpeg gif png pdf].freeze
  # Thumbnail widths in ImageMagick resize notation
  THUMBNAIL_SIZES = %w[2600 1300 1000 500 100 50].freeze

  # The resources a club may upload, keyed by the resource key stored in the
  # database. Extensions outside the allowlist are rejected.
  RESOURCE_KEYS = {
    'headerImage' => {
      name: 'Header Image',
      description: 'Image that will show at the top of every page. Should be at least 2600px wide.',
      allowed_extensions: %w[jpg jpeg gif png]
    }.freeze,
    'logo' => {
      name: 'Logo',
      description: 'Logo graphic',
      allowed_extensions: %w[jpg jpeg gif png]
    }.freeze,
    'style' => {
      name: 'CSS Style',
      description: 'You can override the default WhyJustRun CSS with your own style. ' \
                   'Warning: this may break with updates to WhyJustRun.',
      allowed_extensions: %w[css]
    }.freeze
  }.freeze

  belongs_to :club

  before_destroy :delete_files

  # Returns a map of resource keys to URLs, with additional <key>_<size>
  # entries for thumbnailable files. Used by club layouts.
  def self.for_club(club)
    map = {}
    where(club_id: club.id).each do |resource|
      map[resource.key] = resource.url
      next unless resource.thumbnailable?

      THUMBNAIL_SIZES.each do |size|
        map["#{resource.key}_#{size}"] = resource.url(size)
      end
    end
    map
  end

  # Creates a resource for the club from an uploaded file, replacing any
  # existing resource (and its files) with the same key. The original is
  # stored on the data volume and jpg thumbnails are generated for
  # thumbnailable file types. Raises InvalidUpload when the file is missing or
  # its extension is not allowed for the key.
  def self.save_for_club(club, key, upload, caption = nil)
    # Callers must validate the key against RESOURCE_KEYS first; an unknown
    # key here is a programming error (it becomes part of the file path).
    config = RESOURCE_KEYS.fetch(key)
    raise InvalidUpload, 'No file was uploaded.' if upload.blank?

    extension = File.extname(upload.original_filename).delete_prefix('.').downcase
    unless config[:allowed_extensions].include?(extension)
      raise InvalidUpload, "The given file extension: #{extension}, is not allowed. " \
                           "Provide a file with one of: #{config[:allowed_extensions].join(', ')}"
    end

    where(club_id: club.id, key: key).destroy_all

    resource = create!(club: club, key: key, caption: caption, extension: extension)
    resource.store_file(upload)
    resource
  end

  def thumbnailable?
    THUMBNAILABLE_EXTENSIONS.include?(extension)
  end

  def url(thumbnail = nil)
    cache_buster = Digest::MD5.hexdigest(updated_at.to_fs(:db))
    "#{Settings.dataURL}#{club_id}/#{relative_path(thumbnail)}?#{cache_buster}"
  end

  def relative_path(thumbnail = nil)
    if thumbnail
      "#{key}_#{thumbnail}.jpg"
    else
      "#{key}.#{extension}"
    end
  end

  def absolute_path(thumbnail = nil)
    File.join(Settings.dataFolder, club_id.to_s, relative_path(thumbnail))
  end

  # Writes the uploaded file to the data volume and generates thumbnails
  def store_file(upload)
    FileUtils.mkdir_p(File.dirname(absolute_path))
    File.open(absolute_path, 'wb') { |file| IO.copy_stream(upload.tempfile, file) }
    generate_thumbnails
  end

  private

  def generate_thumbnails
    return unless thumbnailable?

    THUMBNAIL_SIZES.each do |size|
      Thumbnailer.resize(absolute_path, absolute_path(size), size)
    end
  end

  # Removes the original file and any thumbnails from the data volume
  def delete_files
    paths = [absolute_path]
    paths += THUMBNAIL_SIZES.map { |size| absolute_path(size) } if thumbnailable?
    paths.each { |path| FileUtils.rm_f(path) }
  end
end
