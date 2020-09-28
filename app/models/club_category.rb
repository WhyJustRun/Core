class ClubCategory < ApplicationRecord
  has_many :clubs

  def self.club_id
    1
  end
end
