class EventsController < ApplicationController
  before_filter :authenticate_user!, :only => [:event_list_for_user, :process_result_list]

  def respond_to_event_xml_version(wants)
    wants.xml do
      if params[:iof_version] == '2.0.3'
        render :action => :event_list_2, :layout => false
      elsif params[:iof_version] == '3.0'
        render :action => :event_list_3, :layout => false
      end
    end
  end
  
  def calendar
  end

  # This beast of a method finds events based on a number of GET parameters. There are multiple API routes into this method to make the API calls cleaner.
  # 
  # Supported output formats: IOF XML 2.0.3, IOF XML 3.0, FullCalendar compatible JSON, iCal
  #
  # Parameters:
  # start - find all events after this timestamp (optional)
  # end - find all events before this timestamp (optional)
  # club_id - find events within this club - can also find external significant events by passing the parameter specified below (optional)
  # external_significant_events - default: none (options: none, all) (optional, only valid with a specified club_id)
  # club_events - default: all (options: none, significant, all) (optional, only valid with a specified club_id)
  # prefix_club_acronym - default: false (options: true, false, external_only) (optional)
  #
  def index
    # Parse the params
    club_id = (params[:club_id].nil?) ? nil : params[:club_id].to_i
    club = Club.find(club_id) unless club_id.nil?
    prefix_club_acronym = (params[:prefix_club_acronym].nil?) ? "false" : params[:prefix_club_acronym]
    start_time = params[:start].nil? ? nil : Time.at(params[:start].to_i)
    end_time = params[:end].nil? ? nil : Time.at(params[:end].to_i)
    
    # These params are only used if a club is specified
    club_events = (params[:club_events].nil?) ? 'all' : params[:club_events]
    external_significant_events = (params[:external_significant_events].nil?) ? 'none' : params[:external_significant_events]

    # Start building the query
    @events = Event.includes(:series, :club, :event_classification, :courses).order('date ASC')

    unless start_time.nil?
      @events = @events.where("date >= ?", start_time)
    end
    unless end_time.nil?
      @events = @events.where("date <= ?", end_time)
    end
      
    unless club.nil?
      # Build the conditions to find events associated with a club
      expr = nil

      if club_events == "all"
        expr = Event.arel_club_expr(club)
      elsif club_events == "significant"
        expr = Event.arel_club_significant_expr(club)
      end

      if external_significant_events == "all"
        sig_expr = Event.arel_nonclub_significant_expr(club)
        if expr.nil?
          expr = sig_expr
        else 
          expr = expr.or(sig_expr)
        end
      end
      
      if expr.nil?
        @events = []
      else
        @events = @events.where(expr)
      end
    end

    # Helper function to determine if an event's name should be prefixed with the club name
    should_prefix = lambda { |event, club|
      if prefix_club_acronym == 'external_only'
        club.nil? or (event.club != club)
      else
        (prefix_club_acronym == 'true')
      end
    }
    respond_to do |wants|
      wants.ics do
        calendar = Icalendar::Calendar.new
        calendar.custom_property("X-WR-CALNAME", Club.find(club_id).name)
        @events.each { |event|
          calendar.add_event(event.to_ics)
        }
        calendar.publish
        render :text => calendar.to_ical
      end
      wants.json do
        output = []
        @events.each { |event|
          output << event.to_fullcalendar(should_prefix.call(event, club), club_id)
        }
        render :text => output.to_json
      end
      respond_to_event_xml_version(wants)
    end
  end

  def event_list_for_user
    limit = params[:limit] || nil
    @events = Event.limit(limit).joins({:organizers => :user}).order('date DESC').where('users.id = ?', current_user.id)
    
    respond_to do |wants|
      respond_to_event_xml_version(wants)
    end
  end
	
  def show
    @event = Event.find_cascaded(params[:id])
    respond_to do |format|
      format.xml  { render :layout => false }
      format.json  { render :json => @event }
    end
  end
	
  # IOF XML 2.0 for now
  def start_list
    unless params[:iof_version] == '2.0.3'
      raise ActionController::RoutingError.new('Not Found')
    end
		
    @event = Event.find(params[:id])
    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end
	
  # IOF XML 3.0 for now
  def entry_list
    unless params[:iof_version] == '3.0'
      raise ActionController::RoutingError.new('Not Found')
    end
		
    @event = Event.find(params[:id])
    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end
	
  # IOF XML 2.0 for now
  def result_list
    supported = ['2.0.3', '3.0']
    unless supported.include? params[:iof_version] then
      raise ActionController::RoutingError.new('Not Found')
    end
		
    @version = params[:iof_version]
    @event = Event.find(params[:id])
    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end
	
  def process_result_list
    require 'nokogiri'
		
    user = current_user
    if Organizer.where(:event_id => params[:id], :user_id => user.id).count == 0 then
      render :status => :unauthorized
      return
    end
		
    event = {}
    # Strategy:
    # 1. Extract event, and update database if necessary
    # 2. Extract courses, and update database if necessary
    # 3. Extract results, and update database if necessary
    doc = Nokogiri::XML(request.body.read)
		
    results = {}
    results.default = []
		
    if(params[:iof_version] == '2.0.3') then
			
    elsif(params[:iof_version] == '3.0') then
      doc.css('ClassResult').each do |course|
        course_results = []
        course_id = (course.at_css('Class'))['idref'].to_i
        course.xpath("*[name()='PersonResult']").each do |result|
          start_time = result.at_css('Result > StartTime').content
          end_time = result.at_css('Result > EndTime').content
          time_node = result.at_css('Result > Time')
          person_id_node = result.at_css('Person > Id')
          user_id = nil
          unless person_id_node.nil? then user_id = person_id_node.content.to_i end
            unless time_node.nil? then time = time_node.content end
              status_node = result.at_css('Result > Status')
              unless status_node.nil? then status = status_node.content end
                if status.blank? then
                  status = "OK"
                end
                unless(time.blank?) then time_seconds = time.to_i.seconds end
                  unless start_time.blank? or end_time.blank? then
                    time_seconds = (Time.parse(end_time) - Time.parse(start_time)).seconds
                  end
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
		
            event = Event.find(params[:id])
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
