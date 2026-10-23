class Group < ApplicationRecord
  # A group without a club grants platform-wide privileges.
  belongs_to :club, optional: true
  has_many :privileges

  # Groups that a user with the given privilege level is allowed to see and
  # manage (a user can never grant or revoke a level above their own).
  scope :up_to_level, ->(level) { where(access_level: ..level) }
end
