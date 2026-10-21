class ClubsController < ApplicationController
  def index
    @clubs = Club.where(:visible => true).includes(:club_category)
    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end

  # Legacy entry point (/clubsite/:club_id) for links that predate the club
  # sites living in this app. Signed-in visitors are handed to the club site's
  # login URL, which completes single sign-on without prompting.
  def show_clubsite
    club = Club.find_by_id(params[:club_id])
    path = current_user.nil? ? '/' : '/users/login'
    redirect_to club.clubsite_url(path), allow_other_host: true
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
