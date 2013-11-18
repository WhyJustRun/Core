class Map < ActiveRecord::Base

  has_many :event
  belongs_to :map_standard
  belongs_to :club

end
