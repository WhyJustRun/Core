class Group < ActiveRecord::Base
  belongs_to :club
  has_many :privileges
end
