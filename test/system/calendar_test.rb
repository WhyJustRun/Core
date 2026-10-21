require 'application_system_test_case'

class CalendarTest < ApplicationSystemTestCase
  test "the calendar renders the club's events and navigates by month" do
    # Put a fixture event in the middle of the current month so it is on the
    # initially displayed calendar regardless of timezone edges.
    now = Time.now.utc
    events(:cluba_race).update!(date: Time.utc(now.year, now.month, 15, 18), finish_date: nil)

    visit_club '/events/index'

    # FullCalendar builds the grid and fetches /club/:id/events.json
    assert_selector '.fc-event', text: 'Spring Sprint'
    assert_selector '.series-legend li', text: 'Wednesday Evening Series'

    # Month navigation pushes the day-first date of the new view onto the URL
    calendar = find('.wjr-calendar')
    displayed_month = Date.new(calendar['data-calendar-year'].to_i,
                               calendar['data-calendar-month'].to_i + 1, 1)
    next_month = displayed_month >> 1

    find('.fc-button-next').click
    assert_no_selector '.fc-event', text: 'Spring Sprint'
    assert_current_path format('/events/index/01-%02d-%d', next_month.month, next_month.year)

    find('.fc-button-prev').click
    assert_selector '.fc-event', text: 'Spring Sprint'
    assert_current_path format('/events/index/01-%02d-%d', displayed_month.month, displayed_month.year)
  end
end
