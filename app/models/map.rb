class Map < ActiveRecord::Base
  has_many :event
  belongs_to :map_standard
  belongs_to :club

  def url
    "http://" + club.domain + "/maps/view/" + id.to_s
  end
end
