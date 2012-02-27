class ClubsController < ApplicationController
	def index
		@clubs = Club.all
		
		respond_to do |format|
			format.xml  { render :layout => false }
		end
	end
	
	def events
	  @events = Event.limit(50).where("club_id = ?", params[:id]).order('date DESC')
	  
	  respond_to do |wants|
  	  wants.ics do
            calendar = Icalendar::Calendar.new
            calendar.custom_property("X-WR-CALNAME", Club.find(params[:id]).name)
            @events.each { |event|
              calendar.add_event(event.to_ics)
            }
            calendar.publish
            render :text => calendar.to_ical
      end
    end
	end
end
