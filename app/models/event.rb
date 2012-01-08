require 'markdownizer'

class Event < ActiveRecord::Base
	belongs_to :club
	has_one :group
	has_one :map
	belongs_to :series
	has_many :organizers
	has_many :courses 
	
	markdownize! :description
	
	# eager loads courses, results, users, organizers
	def self.find_cascaded(id)
		@event = self.includes(:courses => [{:results => :user}], :organizers => [:user]).find(id)
	end
	
	def url
		club.url + 'event/view/' + id.to_s
	end
	
	def local_date
		Time.zone = club.timezone
		date.in_time_zone
	end
end
