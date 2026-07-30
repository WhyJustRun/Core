require 'test_helper'

class ClubsiteEventEditorTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    host! 'cluba.test'
  end

  # --- Edit form ---

  test "edit form renders for the event's organizer" do
    sign_in users(:organizer)
    get "/events/edit/#{events(:cluba_race).id}"
    assert_response :success
    assert_select 'h1', text: 'Edit Event'
    assert_select "form[action=?]", "/events/edit/#{events(:cluba_race).id}"
  end

  test "edit form renders for an executive and seeds the JSON blobs" do
    sign_in users(:executive)
    get "/events/edit/#{events(:cluba_race).id}"
    assert_response :success
    organizers = JSON.parse(css_select('#EventOrganizers').first['value'])
    assert_equal [users(:organizer).id], organizers.map { |organizer| organizer['id'] }
    assert_equal roles(:organizer).id, organizers.first['role']['id']
    courses = JSON.parse(css_select('#EventCourses').first['value'])
    assert_equal ['Long Course', 'Score Course'], courses.map { |course| course['name'] }.sort
    assert_equal true, courses.find { |course| course['name'] == 'Score Course' }['isScoreO']
  end

  test "edit form redirects a plain member" do
    sign_in users(:member)
    get "/events/edit/#{events(:cluba_race).id}"
    assert_response :redirect
    assert_redirected_to '/'
  end

  test "add form requires the edit privilege" do
    sign_in users(:member)
    get '/events/edit'
    assert_response :redirect

    sign_in users(:executive)
    get '/events/edit'
    assert_response :success
    assert_select 'h1', text: 'Add Event'
  end

  test "series options are limited to current series unless the event's series is not current" do
    old_series = Series.create!(name: 'Old Series', club: clubs(:cluba), is_current: false)
    sign_in users(:executive)

    get "/events/edit/#{events(:cluba_race).id}"
    assert_select '#EventSeriesId option', text: 'Old Series', count: 0

    events(:cluba_race).update_columns(series_id: old_series.id)
    get "/events/edit/#{events(:cluba_race).id}"
    assert_select '#EventSeriesId option', text: 'Old Series'
    assert_select '#EventSeriesId option', text: 'Wednesday Evening Series'
  end

  # --- Saving ---

  test "create assembles dates in the club's time zone and stores UTC" do
    sign_in users(:executive)
    assert_difference 'Event.count', 1 do
      post '/events/edit', params: {
        event: {
          name: 'New Sprint',
          event_classification_id: event_classifications(:local).id,
          date: '2025-06-18', time: '10:00',
          finish_date: '2025-06-18', finish_time: '12:30',
          deadline_date: '2025-06-17', deadline_time: '',
          lat: clubs(:cluba).lat.to_s, lng: clubs(:cluba).lng.to_s,
          organizers: '[]', courses: '[]'
        }
      }
    end
    event = Event.order(:id).last
    assert_redirected_to "/events/view/#{event.id}"
    assert_equal clubs(:cluba).id, event.club_id
    # 10:00 Pacific in June is 17:00 UTC (PDT)
    assert_equal Time.utc(2025, 6, 18, 17, 0), event.date.utc
    assert_equal Time.utc(2025, 6, 18, 19, 30), event.read_attribute(:finish_date).utc
    # Blank deadline time defaults to 23:59 club time
    assert_equal Time.utc(2025, 6, 18, 6, 59), event.registration_deadline.utc
    # The club's default marker position is not stored
    assert_nil event.lat
    assert_nil event.lng
  end

  test "create in winter stores the standard-time UTC offset" do
    sign_in users(:executive)
    post '/events/edit', params: {
      event: {
        name: 'Winter Event',
        event_classification_id: event_classifications(:local).id,
        date: '2025-12-10', time: '10:00',
        organizers: '[]', courses: '[]'
      }
    }
    event = Event.order(:id).last
    # 10:00 Pacific in December is 18:00 UTC (PST)
    assert_equal Time.utc(2025, 12, 10, 18, 0), event.date.utc
  end

  test "organizers blob creates rows and a re-save replaces them" do
    sign_in users(:executive)
    event = events(:cluba_race)
    blob = [
      { id: users(:member).id, name: users(:member).name,
        role: { id: roles(:course_planner).id, name: roles(:course_planner).name } }
    ].to_json
    post "/events/edit/#{event.id}", params: {
      event: base_event_params(event).merge(organizers: blob, courses: '[]')
    }
    assert_redirected_to "/events/view/#{event.id}"
    assert_equal [[users(:member).id, roles(:course_planner).id]],
                 event.organizers.reload.map { |organizer| [organizer.user_id, organizer.role_id] }

    # Saving again with a different blob replaces the rows wholesale
    blob = [
      { id: users(:organizer).id, name: users(:organizer).name,
        role: { id: roles(:organizer).id, name: roles(:organizer).name } }
    ].to_json
    post "/events/edit/#{event.id}", params: {
      event: base_event_params(event).merge(organizers: blob, courses: '[]')
    }
    assert_equal [[users(:organizer).id, roles(:organizer).id]],
                 event.organizers.reload.map { |organizer| [organizer.user_id, organizer.role_id] }
  end

  test "courses blob updates existing courses by id and adds new ones without deleting omitted ones" do
    sign_in users(:organizer)
    event = events(:cluba_race)
    blob = [
      { id: courses(:race_long).id, name: 'Longer Course', description: 'Updated',
        distance: 6000, climb: 200, isScoreO: false },
      { id: nil, name: 'Beginner Course', description: 'New', distance: 2000, climb: 50, isScoreO: true }
    ].to_json
    assert_difference 'event.courses.count', 1 do
      post "/events/edit/#{event.id}", params: {
        event: base_event_params(event).merge(organizers: '[]', courses: blob)
      }
    end
    course = courses(:race_long).reload
    assert_equal 'Longer Course', course.name
    assert_equal 6000, course.distance
    assert_equal 200, course.climb
    new_course = event.courses.find_by(name: 'Beginner Course')
    assert new_course.is_score_o
    # The omitted score course survives (deletion happens via /courses/delete)
    assert Course.exists?(courses(:race_score).id)
  end

  test "save rejects invalid data and re-renders the form" do
    sign_in users(:executive)
    event = events(:cluba_race)
    post "/events/edit/#{event.id}", params: {
      event: base_event_params(event).merge(name: '', organizers: '[]', courses: '[]')
    }
    assert_response :success
    assert_select 'h1', text: 'Edit Event'
    assert_equal 'Spring Sprint', event.reload.name
  end

  # --- Delete ---

  test "delete requires the delete privilege (level 90)" do
    event = events(:cluba_race)
    course_id = courses(:race_long).id
    organizer_id = organizers(:oscar_on_race).id
    sign_in users(:executive)
    post "/events/delete/#{event.id}"
    assert_redirected_to '/'
    assert Event.exists?(event.id)

    sign_in users(:webmaster)
    post "/events/delete/#{event.id}"
    assert_redirected_to '/events/'
    assert_not Event.exists?(event.id)
    assert_not Course.exists?(course_id)
    assert_not Organizer.exists?(organizer_id)
  end

  # --- Planner ---

  test "planner redirects a plain member" do
    sign_in users(:member)
    get '/events/planner'
    assert_response :redirect
    assert_redirected_to '/'
  end

  test "planner renders maps and volunteers for an executive" do
    travel_to Time.utc(2025, 7, 1, 12) do
      sign_in users(:executive)
      get '/events/planner'
      assert_response :success
      assert_select 'h1', text: 'Event Planner'
      assert_select 'td a[href=?]', "/maps/view/#{maps(:cluba_forest).id}", text: 'Forest Map'
      assert_select 'td', text: 'Never used'
      assert_select 'h2', text: "Who's Next?"
    end
  end

  # --- Printable entries ---

  test "printableEntries renders the printable layout with per-course entries" do
    get "/events/printableEntries/#{events(:cluba_race).id}"
    assert_response :success
    assert_match 'clubsite_printable', response.body
    assert_select 'nav', count: 0
    assert_select 'h3', text: /Long Course \(2 participants\)/
    assert_select 'td nobr', text: 'Mary Member'
    # Mary has a current-year membership with the club
    travel_to Time.utc(2026, 6, 1) do
      get "/events/printableEntries/#{events(:cluba_race).id}"
    end
    assert_select 'td', text: '✓'
  end

  # --- Upload maps ---

  test "uploadMaps renders per-course upload forms for the organizer" do
    sign_in users(:organizer)
    get "/events/uploadMaps/#{events(:cluba_race).id}"
    assert_response :success
    assert_select "form[action=?]", "/courses/uploadMap/#{courses(:race_long).id}"
    assert_select "form[action=?]", "/courses/uploadMap/#{courses(:race_score).id}"
  end

  test "uploadMaps redirects a plain member" do
    sign_in users(:member)
    get "/events/uploadMaps/#{events(:cluba_race).id}"
    assert_response :redirect
  end

  # --- Results editor ---

  test "editResults renders the result editor for the organizer" do
    sign_in users(:organizer)
    get "/events/editResults/#{events(:cluba_race).id}"
    assert_response :success
    assert_select ".result-editor[data-event-id=?]", events(:cluba_race).id.to_s
    assert_select "form[action=?]", "/events/editResults/#{events(:cluba_race).id}"
  end

  test "editResults redirects a plain member" do
    sign_in users(:member)
    get "/events/editResults/#{events(:cluba_race).id}"
    assert_response :redirect
  end

  test "update_results saves times, defaults blank status to ok and nulls all-zero times" do
    sign_in users(:organizer)
    event = events(:cluba_race)
    blob = [
      { id: courses(:race_long).id, is_score_o: false, results: [
        { id: results(:member_long).id, user: { id: users(:member).id },
          hours: '1', minutes: '02', seconds: '03', milliseconds: '000',
          status: '', registrant_comment: '', official_comment: 'Nice run' },
        { id: results(:organizer_long).id, user: { id: users(:organizer).id },
          hours: '0', minutes: '00', seconds: '00', milliseconds: '000',
          status: 'did_not_finish', registrant_comment: '', official_comment: '' },
        { user: { id: users(:executive).id },
          hours: '0', minutes: '45', seconds: '10', milliseconds: '500',
          status: 'ok', registrant_comment: '', official_comment: '' }
      ] }
    ].to_json
    post "/events/editResults/#{event.id}", params: { event: { courses: blob, results_posted: '1' } }
    assert_redirected_to "/events/view/#{event.id}"

    member_result = results(:member_long).reload
    assert_equal 3723.0, member_result.time_seconds
    assert_equal :ok, member_result.status
    assert_equal 'Nice run', member_result.official_comment
    assert_nil member_result.registrant_comment

    assert_nil results(:organizer_long).reload.time_seconds
    assert_equal :did_not_finish, results(:organizer_long).status

    new_result = Result.find_by(user_id: users(:executive).id, course_id: courses(:race_long).id)
    assert_in_delta 2710.5, new_result.time_seconds, 0.001

    assert event.reload.results_posted
  end

  test "update_results saves score points and the course's score-o flag" do
    sign_in users(:organizer)
    event = events(:cluba_race)
    blob = [
      { id: courses(:race_score).id, is_score_o: true, results: [
        { user: { id: users(:member).id }, hours: '0', minutes: '50', seconds: '00',
          milliseconds: '000', status: 'ok', score_points: 120 }
      ] }
    ].to_json
    post "/events/editResults/#{event.id}", params: { event: { courses: blob, results_posted: '1' } }
    result = Result.find_by(user_id: users(:member).id, course_id: courses(:race_score).id)
    assert_equal 120, result.score_points
    assert courses(:race_score).reload.is_score_o
  end

  test "update_results rejects a course belonging to another event" do
    sign_in users(:organizer)
    foreign_course = Course.create!(event: events(:cluba_training), name: 'Foreign Course')
    blob = [
      { id: foreign_course.id, is_score_o: false, results: [
        { user: { id: users(:member).id }, hours: '1', minutes: '00', seconds: '00',
          milliseconds: '000', status: 'ok' }
      ] }
    ].to_json
    assert_no_difference 'Result.count' do
      post "/events/editResults/#{events(:cluba_race).id}", params: { event: { courses: blob, results_posted: '1' } }
    end
    assert_redirected_to '/'
    assert_not events(:cluba_race).reload.results_posted
  end

  # --- Live results visibility ---

  test "toggle_live_results_visibility flips the live result list's visible flag" do
    event = events(:cluba_race)
    result_list = ResultList.create!(event: event, user: users(:organizer),
                                     status: ResultList::LIVE_STATUS, data: '<ResultList/>',
                                     upload_time: Time.current, visible: false)
    sign_in users(:organizer)

    post "/events/toggle_live_results_visibility/#{event.id}/true"
    assert_redirected_to "/events/view/#{event.id}"
    assert result_list.reload.visible

    post "/events/toggle_live_results_visibility/#{event.id}/false"
    assert_not result_list.reload.visible
  end

  test "toggle_live_results_visibility redirects a plain member" do
    sign_in users(:member)
    post "/events/toggle_live_results_visibility/#{events(:cluba_race).id}/true"
    assert_redirected_to '/'
  end

  # --- Tenancy ---

  test "another club's domain cannot edit this club's event" do
    host! 'clubb.test'
    sign_in users(:global_admin)
    get "/events/edit/#{events(:cluba_race).id}"
    assert_response :not_found

    post "/events/edit/#{events(:cluba_race).id}",
         params: { event: { name: 'Hijacked', organizers: '[]', courses: '[]' } }
    assert_response :not_found

    post "/events/delete/#{events(:cluba_race).id}"
    assert_response :not_found
    assert Event.exists?(events(:cluba_race).id)
  end

  private

  # Minimal valid form fields for re-saving an existing event
  def base_event_params(event)
    {
      name: event.name,
      event_classification_id: event.event_classification_id,
      series_id: event.series_id,
      date: event.date.strftime('%Y-%m-%d'),
      time: event.date.strftime('%H:%M')
    }
  end
end
