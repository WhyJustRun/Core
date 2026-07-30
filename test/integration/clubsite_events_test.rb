require 'test_helper'

class ClubsiteEventsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    host! 'cluba.test'
  end

  test "index renders the calendar seeded with today's date" do
    get '/events/index'
    assert_response :success
    today = Time.now.utc.in_time_zone('America/Vancouver').to_date
    assert_select '.wjr-calendar[data-calendar-year=?]', today.year.to_s
    assert_select '.wjr-calendar[data-calendar-month=?]', (today.month - 1).to_s
    assert_select '.wjr-calendar[data-calendar-day=?]', today.day.to_s
  end

  test "index parses the day-first date param" do
    get '/events/index/15-06-2025'
    assert_response :success
    assert_select '.wjr-calendar[data-calendar-year="2025"][data-calendar-month="5"][data-calendar-day="15"]'
  end

  test "index shows a legend of current series" do
    get '/events/index'
    assert_response :success
    assert_select "ul.series-legend li.series-#{series(:cluba_wednesday).id}", text: 'Wednesday Evening Series'
  end

  test "listing renders the knockout event list fed by the IOF XML feed" do
    get '/events/listing'
    assert_response :success
    assert_select '.event-list[data-event-list-url=?]',
                  "#{Settings.coreURL.chomp('/')}/club/#{clubs(:cluba).id}/events.xml?iof_version=3.0&external_significant_events=all"
    assert_select 'script#event-box-template'
  end

  test "show renders courses and registrations in the club's local time" do
    event = events(:cluba_race)
    travel_to Time.utc(2025, 6, 1, 12) do
      get "/events/view/#{event.id}"
    end
    assert_response :success
    assert_select 'h1', text: /Spring Sprint/
    # 17:00/19:00 UTC render as Pacific local times
    assert_select 'h2.event-header', text: 'June 15th 2025 10:00am - 12:00pm'
    assert_select 'h3', text: 'Long Course'
    assert_select 'h3', text: 'Score Course'
    assert_select 'a', text: 'Mary Member'
    assert_select 'a', text: 'Oscar Organizer'
  end

  test "show renders the results section once the event has results posted" do
    event = events(:cluba_race)
    event.update_column(:results_posted, true)
    get "/events/view/#{event.id}"
    assert_response :success
    assert_select 'h2', text: 'Results'
    assert_select '.result-list[data-result-list-url=?]',
                  "#{Settings.coreURL.chomp('/')}/iof/3.0/events/#{event.id}/result_list.xml"
    assert_select 'h2', text: 'Course Maps'
  end

  test "results path is an alias for show" do
    event = events(:cluba_race)
    get "/events/results/#{event.id}"
    assert_response :success
    assert_select 'h1', text: /Spring Sprint/
  end

  test "show as json includes the event's associations and status flags" do
    event = events(:cluba_race)
    get "/events/view/#{event.id}.json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'Spring Sprint', body['name']
    assert_equal 'Wednesday Evening Series', body['series']['name']
    assert_equal %w[Long\ Course Score\ Course], body['courses'].map { |course| course['name'] }.sort
    assert_equal 2, body['courses'].sum { |course| course['results'].length }
    assert body['completed']
    assert_not body['registration_open']
  end

  test "show as xml permanently redirects to the IOF result list" do
    event = events(:cluba_race)
    get "/events/view/#{event.id}.xml"
    assert_response :moved_permanently
    assert_redirected_to "/iof/3.0/events/#{event.id}/result_list.xml"
  end

  test "an event with a custom url redirects anonymous visitors" do
    get "/events/view/#{events(:cluba_external).id}"
    assert_redirected_to 'https://example.com/external-event'
  end

  test "an event with a custom url renders with a notice for its organizer" do
    event = events(:cluba_external)
    Organizer.create!(event: event, user: users(:organizer), role: roles(:organizer))
    sign_in users(:organizer)
    get "/events/view/#{event.id}"
    assert_response :success
    assert_includes response.body, 'You are seeing this page because you can edit this event.'
    assert_select 'a[href=?]', 'https://example.com/external-event', text: 'Continue to Event'
  end

  test "rendering 404s when no results file has been uploaded" do
    get "/events/rendering/#{events(:cluba_race).id}"
    assert_response :not_found
  end

  test "rendering 404s for a non-numeric id" do
    get '/events/rendering/nope'
    assert_response :not_found
  end

  test "another club's domain cannot show this club's event" do
    host! 'clubb.test'
    get "/events/view/#{events(:cluba_race).id}"
    assert_response :not_found
  end

  test "embed format renders the calendar without the navbar" do
    get '/events/index.embed'
    assert_response :success
    assert_select '.wjr-calendar'
    assert_select 'nav', count: 0
  end

  test "map renders the marker map in the embed layout" do
    event = events(:cluba_race)
    get "/events/map/#{event.id}"
    assert_response :success
    assert_select '.simple-marker-map[data-lat=?]', event.lat.to_s
    assert_select 'nav', count: 0
  end
end
