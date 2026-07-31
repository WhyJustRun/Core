require 'application_system_test_case'

class EmbedPagesTest < ApplicationSystemTestCase
  test "the calendar embed renders bare and the calendar initializes" do
    now = Time.now.utc
    events(:cluba_race).update!(date: Time.utc(now.year, now.month, 15, 18), finish_date: nil)

    visit_club '/events/index.embed'

    # FullCalendar builds the grid and fetches the club's events
    assert_selector '.wjr-calendar'
    assert_selector '.fc-event', text: 'Spring Sprint'
    assert_selector '.series-legend li', text: 'Wednesday Evening Series'

    # Bare embed layout: no club chrome around the content
    assert_no_selector 'nav.navbar'
    assert_no_selector 'footer'
    assert_no_selector '#content'
  end

  test "the maps embed renders bare and initializes" do
    visit_club '/maps/index.embed'

    assert_selector 'h1', text: 'Maps'
    assert_selector '.multi-marker-map'
    assert_no_selector 'nav.navbar'
    assert_no_selector 'footer'
  end
end
