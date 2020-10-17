class Map < ApplicationRecord
  has_many :event
  belongs_to :map_standard
  belongs_to :club

  def url
    club.clubsite_url("/maps/view/" + id.to_s)
  end
end
