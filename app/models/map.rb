class Map < ApplicationRecord
  has_many :event
  # Legacy records may not have a map standard assigned
  belongs_to :map_standard, optional: true
  belongs_to :club

  validates :name, presence: true

  def url
    club.clubsite_url("/maps/view/" + id.to_s)
  end
end
