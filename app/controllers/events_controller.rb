class EventsController < ApplicationController
  before_filter :authenticate_user!, :only => [:event_list_for_user, :process_result_list]

  def respond_to_event_xml_version(wants)
    wants.xml do
      if params[:version] == '2.0.3'
        render :action => :event_list_2, :layout => false
      elsif params[:version] == '3.0'
        render :action => :event_list_3, :layout => false
      end
    end
  end
  
  def calendar
  end

  def index
    # Crap this whole thing needs refactoring badly.
    club_id = (params[:club_id].nil?) ? nil : params[:club_id].to_i
    prefix_club_acronym = club_id.nil?
    unless params[:prefix_club_acronym].nil?
      puts params[:prefix_club_acronym]
      prefix_club_acronym = (params[:prefix_club_acronym] == "true")
    end
    only_non_club_events = (params[:only_non_club])
    club = Club.find(club_id) unless club_id.nil?
    start_time ||= params[:start].nil? ? nil : Time.at(params[:start].to_i)
    end_time ||= params[:end].nil? ? nil : Time.at(params[:end].to_i)
    list_type = params[:list_type] || nil
    all_club_events = (params[:all_club_events])

    # TODO add limits on largest date range requests
    # limit the number of events except for ical
    @events = Event
    unless start_time.nil?
      @events = @events.where("date >= ?", start_time)
    end
    unless end_time.nil?
      @events = @events.where("date <= ?", end_time)
    end
      
    @events = @events.includes(:series, :club, :event_classification, :courses)
    if (list_type == 'significant')
      center = [club.lat, club.lng]
      significant_events = @events.where("club_id != ?", club_id)
      if only_non_club_events
        # no club events
        club_events = []
      elsif (all_club_events)
        # all club events + significant other events
        club_events = @events.where("club_id = ?", club_id).order('date ASC')
      else
        # only significant club events
        club_events = @events.where("club_id = ?", club_id).where('event_classification_id < ?', EventClassification::CLUB_ID).order('date ASC')
      end
      
      # Find events at other clubs that aren't geotagged but meet the distance criteria
      local_clubs = club.nearbys(Event::LOCAL_DISTANCE).map { |club| club.id }
      regional_clubs = club.nearbys(Event::REGIONAL_DISTANCE).map { |club| club.id }
      national_clubs = club.nearbys(Event::NATIONAL_DISTANCE).map { |club| club.id }
      
      arel_events = Event.arel_table
      non_geotagged_event_query = 
        arel_events[:lat].eq(nil).
        and(arel_events[:club_id].in(local_clubs)
            .and(arel_events[:event_classification_id].eq(EventClassification::LOCAL_ID))
          .or(arel_events[:club_id].in(regional_clubs)
            .and(arel_events[:event_classification_id].eq(EventClassification::REGIONAL_ID)))
          .or(arel_events[:club_id].in(national_clubs)
            .and(arel_events[:event_classification_id].eq(EventClassification::NATIONAL_ID)))
        )
      non_geotagged_events = significant_events.where(non_geotagged_event_query).order('date ASC')
      
      # Find events at other clubs that are geotagged
      local_events = significant_events.where(:event_classification_id => EventClassification::LOCAL_ID).near(center, Event::LOCAL_DISTANCE).order('date ASC')
      regional_events = significant_events.where(:event_classification_id => EventClassification::REGIONAL_ID).near(center, Event::REGIONAL_DISTANCE).order('date ASC')
      national_events = significant_events.where(:event_classification_id => EventClassification::NATIONAL_ID).near(center, Event::NATIONAL_DISTANCE).order('date ASC')

      # Find all international and national events
      international_events = significant_events.where(:event_classification_id => EventClassification::INTERNATIONAL_ID).order('date ASC')
      our_national_events = significant_events.where(:event_classification_id => EventClassification::NATIONAL_ID).where(:club_id => club.national_clubs)

      # Combine results
      significant_events_outside_club = (local_events + regional_events + (non_geotagged_events | our_national_events | national_events) + international_events)
      @events = (significant_events_outside_club + club_events).sort! { |a, b| a.date <=> b.date }
    else
      # normal filter, for regular clubs
      unless club_id.nil?
        @events = @events.where("club_id = ?", club_id).order('date ASC')
      end
    end

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
          output << event.to_fullcalendar(prefix_club_acronym, club_id)
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
    unless params[:version] == '2.0.3'
      raise ActionController::RoutingError.new('Not Found')
    end
		
    @event = Event.find(params[:id])
    respond_to do |format|
      format.xml  { render :layout => false }
    end
  end
	
  # IOF XML 3.0 for now
  def entry_list
    unless params[:version] == '3.0'
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
    unless supported.include? params[:version] then
      raise ActionController::RoutingError.new('Not Found')
    end
		
    @version = params[:version]
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
		
    if(params[:version] == '2.0.3') then
			
    elsif(params[:version] == '3.0') then
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
