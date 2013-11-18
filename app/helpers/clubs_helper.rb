require 'csv'

module ClubsHelper

	def participant_counts_helper
	  CSV.generate do |csv|
	    csv << ['ID', 'Date', 'Name', 'Series Name', 'Number of Participants', 'Club', "Organizers", 'Map']
	    events = Event.where(:club_id => Club.find(params[:club_id]).all_ancestors)
            events = events.order(:date).includes(:club, :series, :map, :organizers => [:user, :role])
            events.each do |event|
              organizers = event.organizers.map { |organizer|
                organizer.user.name + " (" + organizer.role.name + ")"
              }
              series = event.series
              map = event.map
	      csv << [event.id, event.date, event.name, (series != nil) ? series.name : nil, event.number_of_participants, event.club.name, organizers.join(", "), map ? map.name : nil]
	    end
	  end
	end

end
