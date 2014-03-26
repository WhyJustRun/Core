class MapsController < ApplicationController
  # params: max_lat, max_lng, min_lat, min_lng (all required), optional: club_id
  def index
    max_lat = params[:max_lat]
    min_lat = params[:min_lat]
    max_lng = params[:max_lng]
    min_lng = params[:min_lng]
    club_id = params[:club_id]
    @maps = Map.where('lat <= ?', max_lat).where('lat >= ?', min_lat)
               .where('lng <= ?', max_lng).where('lng >= ?', min_lng)
               .includes(:club)
    unless club_id.nil?
      @maps = @maps.where('club_id = ?', club_id)
    end

    respond_to do |format|
      format.json { render layout: false }
    end
  end
end
