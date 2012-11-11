require 'action_view'

class Event < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper
  
  reverse_geocoded_by :lat, :lng
  
  belongs_to :club
  has_one :map
  belongs_to :series
  belongs_to :event_classification
  has_many :organizers
  has_many :courses 
		
  # eager loads courses, results, users, organizers
  def self.find_cascaded(id)
    @event = self.includes(:courses => [{:results => :user}], :organizers => [:user]).find(id)
  end
	
  def local_date
    date.in_time_zone(club.timezone)
  end
  
  def end_date
    actual_end_date = read_attribute(:end_date)
    actual_end_date ||= date + 1.hour
    return actual_end_date
  end
  
  def local_end_date
    end_date.in_time_zone(club.timezone)
  end
	
  def has_location
    self.lat != nil and self.lng != nil
  end
	
  def address
    require "geocoder"
    geo = Geocoder.search("#{lat},#{lng}")
    if(geo.first != nil)
      return geo.first.address
    end
  end
	
  def url
    if custom_url != nil
      custom_url 
    else
      "http://" + club.domain + "/events/view/" + id.to_s
    end
  end
	
  def rendered_description
    BlueCloth.new(description).to_html
  end
  
  def number_of_participants
  	actual_count = read_attribute(:number_of_participants)
  	if (actual_count.nil?) then
  		courses = Course.where(:event_id => self.id).select(:id)
  		actual_count = Result.where(:course_id => courses).where('status != \'did_not_start\'').count
  	end
  	
  	return actual_count
  end
	
  def to_ics
    Time.zone = "UTC"
    event = Icalendar::Event.new
    event.start = date.strftime("%Y%m%dT%H%M%S") + "Z"
    event.end = end_date.strftime("%Y%m%dT%H%M%S") + "Z"
    event.summary = name
    event.description = strip_tags(rendered_description)
    if has_location
      event.geo = Icalendar::Geo.new(lat, lng)
      event.location = "#{lat.round(4)},#{lng.round(4)}"
    end
    event.klass = "PUBLIC"
    # TODO-RWP event.created = self.created_at
    # TODO-RWP event.last_modified = self.updated_at
    event.uid = event.url = url
    event
  end
  
  def to_fullcalendar
    Time.zone = "UTC"
    out = {}
    out[:id] = id
    out[:title] = name
    out[:start] = date.to_i
    out[:end] = end_date.to_i
    if event_classification
      out[:event_classification] = {
        :id => event_classification.id,
        :name => event_classification.name
      }
    end
    out[:allDay] = false
    if has_location
      out[:lat] = lat
      out[:lng] = lng
    end
    out[:url] = url
    if series.nil?
        out[:textColor] = '#000000'
    else
        out[:textColor] = series.color
    end
    out[:color] = '#ffffff'
    out
  end
end
