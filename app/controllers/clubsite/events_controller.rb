module Clubsite
  # Event pages: the calendar, the event list, individual event pages with
  # registrations, results and course maps, plus the event editor, results
  # editor and planner.
  class EventsController < BaseController
    # Number of extra blank rows on the printable entries list
    NUM_BLANK_ENTRIES = 5

    # Planner thresholds: people who attended at least ATTENDANCE_THRESHOLD
    # events since DATE_THRESHOLD ago without organizing are suggested as
    # volunteers.
    PLANNER_DATE_THRESHOLD = 5.months
    PLANNER_ATTENDANCE_THRESHOLD = 5

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

    # Add/edit form. Add when no id is given (legacy URL shape).
    def edit
      @event = find_event_or_new
      authorize @event, @event.new_record? ? :create? : :update?
      prepare_edit_form(@event)
    end

    # Handles the edit form POST for both add and edit.
    def save
      @event = find_event_or_new
      authorize @event, @event.new_record? ? :create? : :update?

      organizers = parse_json_blob(params.dig(:event, :organizers))
      courses = parse_json_blob(params.dig(:event, :courses))
      assign_event_fields(@event)

      if persist_event(@event, organizers, courses)
        flash[:success] = 'The event has been updated.'
        redirect_to "/events/view/#{@event.id}"
      else
        flash.now[:danger] = 'The event could not be updated.'
        prepare_edit_form(@event,
                          organizers_json: params.dig(:event, :organizers),
                          courses_json: params.dig(:event, :courses))
        render :edit
      end
    end

    def destroy
      event = current_club.events.find(params[:id])
      authorize event, :destroy?
      # Destroys organizers, courses and the result list through the model
      # associations; course results cascade at the database level.
      event.destroy
      flash[:success] = 'The event was deleted.'
      redirect_to '/events/'
    end

    # Planning aids: maps that haven't been used recently and regular
    # attendees who haven't volunteered as organizers.
    def planner
      authorize Event.new(club: current_club), :plan?
      @date_threshold = PLANNER_DATE_THRESHOLD.ago
      @attendance_threshold = PLANNER_ATTENDANCE_THRESHOLD
      @maps = planner_maps
      @volunteers = planner_volunteers
    end

    # Printable per-course entry list for use at the registration desk
    def printable_entries
      @event = current_club.events.includes(courses: { results: :user }).find(params[:id])
      @sorted_results = @event.courses.index_by(&:id)
                              .transform_values { |course| course.results.sort_by { |result| result.user.name } }
      render layout: 'clubsite/printable'
    end

    # Lists the event's courses with per-course map upload forms (the upload
    # itself is handled by CoursesController#upload_map).
    def upload_maps
      @event = current_club.events.find(params[:id])
      authorize @event, :update?
      @courses = @event.courses
    end

    # Knockout-based results editor; the initial data is fetched client-side
    # from the event JSON.
    def edit_results
      @event = current_club.events.find(params[:id])
      authorize @event, :update?
    end

    # Saves the results editor form. Courses arrive as a JSON blob of
    # {id, is_score_o, results: [...]} hashes.
    def update_results
      @event = current_club.events.find(params[:id])
      authorize @event, :update?

      allowed_course_ids = @event.courses.pluck(:id)
      courses = parse_json_blob(params.dig(:event, :courses))

      # Security check: every course being edited must belong to this event
      unless (courses.map { |course| course['id'].to_i } - allowed_course_ids).empty?
        return redirect_to '/', alert: 'You are not authorized to edit those courses.'
      end

      begin
        ActiveRecord::Base.transaction do
          courses.each do |course_data|
            save_course_results(course_data, allowed_course_ids)
            course = @event.courses.find(course_data['id'])
            course.update!(is_score_o: boolean_param(course_data['is_score_o']))
          end
          @event.update!(results_posted: boolean_param(params.dig(:event, :results_posted))) if courses.any?
        end
      rescue ActiveRecord::RecordInvalid
        flash[:danger] = 'The results could not be updated.'
        return redirect_to "/events/editResults/#{@event.id}"
      end

      redirect_to "/events/view/#{@event.id}"
    end

    # Shows or hides the event's live result list
    def toggle_live_results_visibility
      @event = current_club.events.find(params[:id])
      authorize @event, :update?
      live_result = ResultList.find_by(event_id: @event.id, status: ResultList::LIVE_STATUS)
      live_result&.update(visible: params[:visible] == 'true')
      redirect_to "/events/view/#{@event.id}"
    end

    private

    def find_event_or_new
      params[:id].present? ? current_club.events.find(params[:id]) : current_club.events.new
    end

    def prepare_edit_form(event, organizers_json: nil, courses_json: nil)
      @maps = current_club.maps.order(:name)
      @series_options = series_options(event)
      @event_classifications = EventClassification.all
      @organizers_json = organizers_json || organizers_to_json(event)
      @courses_json = courses_json || courses_to_json(event)
    end

    # Only current series are offered, unless the event is already assigned to
    # a non-current series (in which case all are offered, current first).
    def series_options(event)
      if event.persisted? && event.series && !event.series.is_current
        current_club.series.order(is_current: :desc)
      else
        current_club.series.where(is_current: true)
      end
    end

    def organizers_to_json(event)
      return '[]' if event.new_record?

      event.organizers.includes(:user, :role).map do |organizer|
        {
          id: organizer.user_id,
          name: organizer.user.name,
          role: { id: organizer.role_id, name: organizer.role&.name }
        }
      end.to_json
    end

    def courses_to_json(event)
      return '[]' if event.new_record?

      event.courses.map do |course|
        {
          id: course.id,
          name: course.name,
          distance: course.distance,
          climb: course.climb,
          description: course.description,
          isScoreO: course.is_score_o
        }
      end.to_json
    end

    def parse_json_blob(value)
      JSON.parse(value.presence || '[]')
    rescue JSON::ParserError
      []
    end

    def assign_event_fields(event)
      event.assign_attributes(event_params)
      event.club = current_club

      # Separate date and time inputs are combined in the club's time zone
      # (the request runs inside Time.use_zone).
      event.date = combine_date_time(params.dig(:event, :date), params.dig(:event, :time))
      event.finish_date = combine_date_time(params.dig(:event, :finish_date), params.dig(:event, :finish_time))
      event.registration_deadline = registration_deadline_param

      # The map marker defaults to the club's location; don't store it
      if event.lat.to_f == current_club.lat.to_f && event.lng.to_f == current_club.lng.to_f
        event.lat = nil
        event.lng = nil
      end
    end

    def event_params
      params.require(:event).permit(
        :name, :event_classification_id, :series_id, :map_id, :description,
        :custom_url, :registration_url, :results_url, :routegadget_url,
        :facebook_url, :attackpoint_url, :number_of_participants, :is_ranked,
        :lat, :lng
      )
    end

    def combine_date_time(date, time)
      return nil if date.blank?

      Time.zone.parse("#{date} #{time}")
    rescue ArgumentError
      nil
    end

    # The deadline time defaults to the end of the chosen day
    def registration_deadline_param
      date = params.dig(:event, :deadline_date)
      return nil if date.blank?

      time = params.dig(:event, :deadline_time).presence || '23:59'
      combine_date_time(date, time)
    end

    def persist_event(event, organizers, courses)
      ActiveRecord::Base.transaction do
        # Legacy behavior: organizers are deleted and recreated on every save
        event.organizers.destroy_all if event.persisted?
        raise ActiveRecord::Rollback unless event.save

        organizers.each do |organizer_data|
          event.organizers.create!(user_id: organizer_data['id'],
                                   role_id: organizer_data.dig('role', 'id'))
        end

        # Courses are updated in place by id and added when new; removed
        # courses are deleted separately by the course editor UI.
        courses.each do |course_data|
          course = course_data['id'].present? ? event.courses.find(course_data['id']) : event.courses.build
          course.update!(name: course_data['name'],
                         distance: course_data['distance'],
                         climb: course_data['climb'],
                         description: course_data['description'],
                         is_score_o: boolean_param(course_data['isScoreO']))
        end

        true
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end

    def boolean_param(value)
      ActiveModel::Type::Boolean.new.cast(value) || false
    end

    # Club maps ordered by when they last hosted an event, least recently
    # used first. Returns [map, last_event] pairs; last_event is nil for
    # never-used maps.
    def planner_maps
      latest_events = current_club.events.where.not(map_id: nil).order(:date).index_by(&:map_id)
      current_club.maps
                  .sort_by { |map| latest_events[map.id]&.date || Time.zone.at(0) }
                  .map { |map| [map, latest_events[map.id]] }
    end

    # Club members who attended enough recent events (anywhere) but haven't
    # organized any. Returns [user, attended_count] pairs, most active first.
    def planner_volunteers
      threshold_time = @date_threshold
      attendance = Result.joins(course: :event)
                         .where('events.date > ?', threshold_time)
                         .group(:user_id)
                         .order(Arel.sql('COUNT(results.user_id) DESC'))
                         .count
      attendance.select! { |_user_id, count| count >= @attendance_threshold }

      organized = Organizer.joins(:event)
                           .where('events.date > ?', threshold_time)
                           .group(:user_id)
                           .count

      volunteer_ids = (attendance.keys - organized.keys) & current_club.users.pluck(:id)
      users = User.where(id: volunteer_ids).index_by(&:id)
      volunteer_ids.filter_map { |user_id| users[user_id] && [users[user_id], attendance[user_id]] }
    end

    def save_course_results(course_data, allowed_course_ids)
      Array(course_data['results']).each do |result_data|
        result = if result_data['id'].present?
                   Result.where(course_id: allowed_course_ids).find_by(id: result_data['id'])
                 end
        result ||= Result.new

        attributes = {
          user_id: result_data.dig('user', 'id'),
          course_id: course_data['id'],
          time_seconds: time_from_parts(result_data),
          status: result_data['status'].presence || 'ok',
          registrant_comment: result_data['registrant_comment'].presence,
          official_comment: result_data['official_comment'].presence
        }
        attributes[:score_points] = result_data['score_points'] if result_data['score_points'].present?

        result.update!(attributes)
      end
    end

    # An all-zero time means no time was recorded
    def time_from_parts(result_data)
      hours = result_data['hours'].to_i
      minutes = result_data['minutes'].to_i
      seconds = result_data['seconds'].to_i
      milliseconds = result_data['milliseconds'].to_i
      return nil if hours.zero? && minutes.zero? && seconds.zero? && milliseconds.zero?

      (3600 * hours) + (60 * minutes) + seconds + (0.001 * milliseconds)
    end

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
