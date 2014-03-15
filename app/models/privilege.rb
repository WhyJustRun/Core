class Privilege < ActiveRecord::Base
  # avoid namespace conflict with ActiveRecord group method
  belongs_to :user_group, class_name: 'Group', foreign_key: 'group_id'
  belongs_to :user
end
