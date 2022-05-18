class ClubsController < ApplicationController
  def index
    @clubs = Club.where(:visible => true).includes(:club_category)
    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end

  # provides a CSV file with participant counts for the club events and any child club events
  def participant_counts
  	respond_to do |format|
  		format.csv { render :layout => false }
  	end
  end

  def map
    @clubs = Club.all_leaves.where(:visible => true)
  end
end
