class Page < ApplicationRecord
  belongs_to :club

  validates :name, presence: true
end
