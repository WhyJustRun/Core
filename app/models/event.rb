require 'action_view'

class Event < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper
  
  after_validation :reverse_geocode
	belongs_to :club
	has_one :group
	has_one :map
	belongs_to :series
	has_many :organizers
	has_many :courses 
		
	# eager loads courses, results, users, organizers
	def self.find_cascaded(id)
		@event = self.includes(:courses => [{:results => :user}], :organizers => [:user]).find(id)
	end
	
	def local_date
		Time.zone = club.timezone
		date.in_time_zone
	end
	
	def has_location
	  self.lat != nil and self.lng != nil
	end
	
	def address
	  require "geocoder"
	  geo = Geocoder.search("#{lat},#{lng}")
	  if(geo.first != nil) then
      return geo.first.address
    end
	end
	
	def url
	  if custom_url != nil then
	    custom_url 
	  else
	    "http://" + club.domain + "/events/view/" + id.to_s
	  end
	end
	
	def rendered_description
	  BlueCloth.new(description).to_html
	end
	
	def to_ics
    event = Icalendar::Event.new
    event.start = date.strftime("%Y%m%dT%H%M%S") + "Z"
    event.end = (date + 1.hour).strftime("%Y%m%dT%H%M%S") + "Z"
    event.summary = name
    event.description = strip_tags(rendered_description)
    if has_location then
      event.geo = Icalendar::Geo.new(lat, lng)
      event.location = address
    end
    event.klass = "PUBLIC"
    # TODO-RWP event.created = self.created_at
    # TODO-RWP event.last_modified = self.updated_at
    event.uid = event.url = url
    event
	end
end
