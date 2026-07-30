module Clubsite
  # Read-only event pages: the calendar, the event list, and individual event
  # pages with registrations, results and course maps.
  class EventsController < BaseController
    def index
      if params[:date].present? && params[:date].include?('-')
        # Day-first date, e.g. /events/index/15-06-2025
        @day, @month, @year = params[:date].split('-')
      else
        today = Time.zone.today
        @day = today.day
        @month = today.month
        @year = today.year
      end

      @series = current_club.series.where(is_current: true)
    end

    def listing
    end

    def show
      if request.format.xml?
        redirect_to "/iof/3.0/events/#{params[:id]}/result_list.xml", status: :moved_permanently
        return
      end

      @event = current_club.events
                           .includes(:series, :map, :event_classification, :result_list,
                                     organizers: %i[user role],
                                     courses: { results: :user })
                           .find(params[:id])
      @can_edit = policy(@event).update?

      # Events with an external page redirect everybody except editors, who
      # instead see the page with a notice (see _redirect_view).
      if @event.custom_url.present? && !@can_edit
        redirect_to @event.custom_url, allow_other_host: true
        return
      end

      @completed = @event.completed?
      @registration_open = @event.registration_open?
      @has_results = @event.has_results?
      @sorted_results = @event.courses.index_by(&:id).transform_values(&:sorted_results)
      @registered_course_ids = registered_course_ids(@event)

      render json: event_json(@event) if request.format.json?
    end

    # Google map for a single event, always rendered bare for embedding
    def map
      @event = current_club.events.find(params[:id])
      render layout: 'clubsite/embed', formats: [:html]
    end

    # Serves the manually uploaded results rendering for an event
    def rendering
      id = begin
        Integer(params[:id])
      rescue ArgumentError, TypeError
        raise ActiveRecord::RecordNotFound
      end

      path = MediaStore.new(current_club.id, 'Event').file_path(id)
      raise ActiveRecord::RecordNotFound if path.nil?

      send_file path, disposition: :inline
    end

    private

    # .embed requests reuse the html templates; only the layout differs (see
    # BaseController#club_layout).
    def default_render
      if request.format == :embed
        render action_name, formats: [:html]
      else
        super
      end
    end

    def registered_course_ids(event)
      return [] unless user_signed_in?

      event.courses.select { |course| course.results.any? { |result| result.user_id == current_user.id } }
           .map(&:id)
    end

    def event_json(event)
      event.as_json(
        methods: [:url],
        include: {
          series: {},
          map: {},
          event_classification: {},
          result_list: { except: [:data] },
          organizers: { include: { user: { only: %i[id name] }, role: {} } },
          courses: { include: { results: { include: { user: { only: %i[id name si_number] } } } } }
        }
      ).merge(
        'completed' => @completed,
        'registration_open' => @registration_open,
        'has_results' => @has_results
      )
    end
  end
end
