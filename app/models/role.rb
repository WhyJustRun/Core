# Organizer roles (e.g. Course Planner). Shared between all clubs.
class Role < ApplicationRecord
  has_many :organizers
end
