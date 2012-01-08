class Club < ActiveRecord::Base
	has_many :users
	has_many :events
	has_many :maps
	has_many :groups
	has_many :content_blocks
	has_many :memberships
	has_many :pages
	has_many :roles
	has_many :series
end
