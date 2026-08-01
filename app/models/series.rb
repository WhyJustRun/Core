class Series < ApplicationRecord
  belongs_to :club
  has_many :events

  validates :acronym, format: { with: /\A[a-zA-Z0-9]+\z/, message: 'may only contain letters and numbers' },
                      allow_blank: true
end
