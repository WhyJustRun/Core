class LiveResultsController < ApplicationController
  before_filter :authenticate_user!, :only => :process_live_result_list

  def process_live_result_list
    result = LiveResult.find_or_initialize_by event_id: params[:id]
    result.user_id = current_user.id
    result.data = request.body.read
    result.upload_time = Time.now
    result.save  
  end

  def live_result_list
    result = LiveResult.find_by event_id: params[:id]
    expires_in 5.seconds, :public => true
    if stale?(last_modified: result.updated_at.utc, etag: result.cache_key)
      respond_to do |format|
        format.xml { render :xml => result.data }
      end
    end
  end
end
