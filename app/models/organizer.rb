class Organizer < ActiveRecord::Base
  belongs_to :event
  belongs_to :user
  belongs_to :role
end
