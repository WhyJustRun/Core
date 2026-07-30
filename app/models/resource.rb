require 'digest/md5'

# Club branding assets (header image, logo, custom stylesheet) stored on the
# shared data volume as <dataFolder>/<club_id>/<key>.<extension> with jpg
# thumbnails alongside.
class Resource < ApplicationRecord
  THUMBNAILABLE_EXTENSIONS = %w[jpg jpeg gif png pdf].freeze
  # Thumbnail widths in ImageMagick resize notation
  THUMBNAIL_SIZES = %w[2600 1300 1000 500 100 50].freeze

  belongs_to :club

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
end
