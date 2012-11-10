require 'csv'

module ClubsHelper

	def participant_counts_helper
	  CSV.generate do |csv|
	    csv << ['ID', 'Date', 'Name', 'Number of Participants', 'Club']
	    Event.where(:club_id => Club.all_ancestors(params[:club_id])).order(:date).each do |event|
	      csv << [event.id, event.date, event.name, event.number_of_participants, event.club.name]
	    end
	  end
	end

end
