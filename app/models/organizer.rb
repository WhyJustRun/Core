class Organizer < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :role
end
