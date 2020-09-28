class EventsController < ApplicationController
  before_action :authenticate_user!, :only => [:event_list_for_user, :process_result_list]

  def respond_to_event_xml_version(wants)
    wants.xml do
      if params[:iof_version] == '2.0.3'
        render :action => :event_list_2, :layout => false
      elsif params[:iof_version] == '3.0'
        render :action => :event_list_3, :layout => false
      else
        raise ActionController::RoutingError.new('Not Found')
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
    @events = Event.list_includes.order('date ASC')

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
        render :plain => calendar.to_ical
      end
      wants.json do
        output = []
        @events.each { |event|
          output << event.to_fullcalendar(should_prefix.call(event, club), club)
        }
        render :plain => output.to_json
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
    @events = []
    event = Event.list_includes.find_by id: params[:id]
    @events = [event] unless event.nil?
    respond_to do |format|
      respond_to_event_xml_version(format)
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
end
