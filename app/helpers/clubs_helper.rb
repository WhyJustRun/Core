require 'csv'

module ClubsHelper

	def participant_counts_helper
	  CSV.generate do |csv|
	    csv << ['ID', 'Date', 'Name', 'Series Name', 'Number of Participants', 'Club', "Organizers", 'Map']
	    events = Event.where(:club_id => Club.find(params[:club_id]).all_siblings)
            events = events.order(:date).includes(:club, :series, :map, :organizers => [:user, :role])
            events.each do |event|
              organizers = event.organizers.map { |organizer|
                organizer.user.name + " (" + organizer.role.name + ")"
              }
              series = event.series
              map = event.map
	      csv << [event.id, event.date, csv_safe(event.name), csv_safe(series&.name), event.number_of_participants, csv_safe(event.club.name), csv_safe(organizers.join(", ")), csv_safe(map&.name)]
	    end
	  end
	end

	private

	# Neutralizes spreadsheet formula injection: a cell whose first character
	# is one of = + - @ (or a leading tab/CR) is treated as a formula by Excel
	# and Sheets, so prefix those values with an apostrophe.
	def csv_safe(value)
	  str = value.to_s
	  str = "'" + str if str.match?(/\A[=+\-@\t\r]/)
	  str
	end

end
