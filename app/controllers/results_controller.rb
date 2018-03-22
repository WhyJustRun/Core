require 'nokogiri'

class ResultsController < ApplicationController
  before_filter :authenticate_user!, :only => :update_live

  def check_event_id id
    unless Event.exists? id
      raise 'you must provide an event id'
    end
  end

  def update_live_result_list
    event_id = params[:id]
    check_event_id event_id
    result_list = ResultList.find_or_initialize_by event_id: event_id, status: ResultList::LIVE_STATUS
    authorize result_list
    result_list.user_id = current_user.id
    result_list.data = request.body.read
    result_list.upload_time = Time.now
    result_list.save
  end

  def live_result_list
    result = ResultList.find_by(event_id: params[:id], status: ResultList::LIVE_STATUS) or not_found_404
    expires_in 5.seconds, :public => true
    if stale?(last_modified: result.updated_at.utc, etag: result.cache_key)
      respond_to do |format|
        format.xml { render :xml => result.data }
      end
    end
  end

  # TODO: This is the WIP replacement to process_result_list...
  # Request body is the XML to store
  # URL parameters
  def update_result_list
    # event_id = params[:id]
    # resolutions = JSON.parse(param[:resolutions])
    # data = params[:file].read
    event_id = 1404
    resolutions = []
    data = File.read('/tmp.xml')

    check_event_id event_id
    data = ResultList.resolve_result_list_user_conflicts(resolutions, data)

    result_list = ResultList.find_or_initialize_by event_id: event_id, status: ResultList::FINAL_STATUS
    authorize result_list
    result_list.user_id = current_user.id
    result_list.data = data
    result_list.upload_time = Time.now

    # Check if there are any remaining unresolved users
    remaining_conflicts = ResultList.result_list_user_conflicts event_id, data
    if remaining_conflicts.length > 0
      # Reply with remaining conflicts.
    elsif result_list.save
      result_list.sync_result_list
    else
      # TODO handle validation error
    end

    render :text => remaining_conflicts.to_yaml
  end

  def result_list
    supported = ['2.0.3', '3.0']
    unless supported.include? params[:iof_version] then
      raise ActionController::RoutingError.new('Not Found')
    end

    @version = params[:iof_version]
    @event = Event.find(params[:id])
    respond_to do |format|
      format.xml do
        if params[:iof_version] == '2.0.3'
          render :action => :result_list_2, :layout => false
        elsif params[:iof_version] == '3.0'
          render :action => :result_list_3, :layout => false
        end
      end
    end
  end

  # TODO: this should have been replaced by update_result_list a long time ago.
  def process_result_list
    user = current_user
    event = Event.find(params[:id])
    authorize event, :update?

    # Strategy:
    # 1. Extract event, and update database if necessary
    # 2. Extract courses, and update database if necessary
    # 3. Extract results, and update database if necessary
    doc = Nokogiri::XML(request.body.read)

    results = {}
    results.default = []

    if(params[:iof_version] == '3.0') then
      doc.css('ClassResult').each do |course|
        course_results = []
        course_class = course.at_css('Class')
        course_id = course_class['idref'].to_i
        if course_id == 0 then
          course_id = course_class.at_css('Id[type=WhyJustRun]')&.content.to_i
        end
        if course_id == 0 then
          raise ActionController::BadRequest.new("Invalid course ID")
        end
        course.xpath("*[name()='PersonResult']").each do |result|
          start_time = result.at_css('Result > StartTime')&.content
          end_time = result.at_css('Result > EndTime')&.content
          time_node = result.at_css('Result > Time')
          person_id_node = result.at_css('Person > Id')
          user_id = nil
          unless person_id_node.nil? then
            user_id = person_id_node.content.to_i
          end
          unless time_node.nil? then
            time = time_node.content
          end
          status_node = result.at_css('Result > Status')
          unless status_node.nil? then
            status = status_node.content
          end
          if status.blank? then
            status = "OK"
          end
          unless time.blank? then
            time_seconds = time.to_i.seconds
          end
          unless start_time.blank? or end_time.blank? then
            time_seconds = (Time.parse(end_time) - Time.parse(start_time)).seconds
          end
          logger.info "Added course result. User: #{user_id} Course: #{course_id}"
          course_results << {
            :name => result.at_css('Person > Name > Given').content + " " + result.at_css('Person > Name > Family').content,
            :id => user_id,
            :time_seconds => time_seconds,
            :status => status
          }
          results[course_id] = course_results
        end
      end
    else
      raise ActionController::RoutingError.new('Not Found')
    end

    event.results_posted = 1
    event.save

    event.courses.each { |course|
      existing_results = course.results
      matched_existing_results = []
      results[course.id].each { |result|
        matched = false
        # Try to match up results - could have a better algorithm that isn't O(n^2)
        existing_results.each { |existing_result|

          if(existing_result.user.id == result[:id]) then
            matched = true
          elsif(result[:id].blank? and not result[:name].blank? and existing_result.user.name == result[:name]) then
            matched = true
          end

          if matched then
            existing_result.iof_status = result[:status]
            existing_result.time_seconds = result[:time_seconds]
            existing_result.save
            matched_existing_results << existing_result
            break
          end
        }

        unless matched then
          # create a new result if it isn't already in the database..
          if result[:id].blank? then
            matches = User.where(:name => result[:name]).all
            if(matches.length == 1) then
              new_result = Result.create(:user_id => matches.first.id, :time_seconds => result[:time_seconds], :course_id => course.id)
              new_result.save
            elsif(matches.length > 1)
              # don't insert if there are more than one possible people..
              render :status => :bad_request
              return
            else
              # create new user
              new_result = Result.create(:time_seconds => result[:time_seconds], :course_id => course.id)
              user = User.create(:name => result[:name])
              new_result.user_id = user.id
              new_result.save
            end
          else
            new_result = Result.create(:user_id => result[:id], :time_seconds => result[:time_seconds], :course_id => course.id)
            new_result.save
          end
        end
      }

      results_to_delete = existing_results - matched_existing_results
      results_to_delete.each { |r|
        logger.info "Deleted result: #{r.id}"
        Result.destroy(r.id)
      }
    }

    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end
end
