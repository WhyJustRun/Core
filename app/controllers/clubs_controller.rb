class ClubsController < ApplicationController
  def index
    @clubs = Club.where(:visible => true).includes(:club_category)
    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end

  def show_clubsite
    club = Club.find_by_id(params[:club_id])
    if current_user.nil?
      url = club.clubsite_url('/')
    else
      cross_session = CrossAppSession.find_by cross_app_session_id: session[:cross_app_session_id]
      # If we don't have a cross app session yet, create it.
      if cross_session.nil?
        cross_session = CrossAppSession.new_for_user(current_user)
        session[:cross_app_session_id] = cross_session.cross_app_session_id
        cross_session.save
      end
      url = club.clubsite_url("/users/localLogin?cross_app_session_id=" + cross_session.cross_app_session_id)
    end

    redirect_to url, allow_other_host: true
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
