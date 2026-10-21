class Map < ApplicationRecord
  # An http(s) (or scheme-less) web address. Constrains the admin-supplied
  # file_url so maps/download can't be turned into a javascript:/data: or
  # arbitrary-scheme redirect. Mirrors Event::URL_FORMAT.
  URL_FORMAT = %r{\A(?:https?://)?(?:[\w-]+\.)+[a-z]{2,}(?::\d+)?(?:/\S*)?\z}i

  has_many :event
  # Legacy records may not have a map standard assigned
  belongs_to :map_standard, optional: true
  belongs_to :club

  validates :name, presence: true
  validates :file_url, format: { with: URL_FORMAT }, allow_blank: true

  def url
    club.clubsite_url("/maps/view/" + id.to_s)
  end
end
