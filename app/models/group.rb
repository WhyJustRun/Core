class Group < ApplicationRecord
  belongs_to :club
  has_many :privileges
end
