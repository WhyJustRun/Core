require 'application_system_test_case'

class PrintableEntriesTest < ApplicationSystemTestCase
  test "the printable entries page lists registrations with member checkmarks" do
    event = events(:cluba_race)
    results(:member_long).update!(registrant_comment: 'Needs a ride')

    sign_in_to_club users(:executive)
    visit_club "/events/printableEntries/#{event.id}"

    # The printable layout renders bare, without the club chrome
    assert_selector 'h2', text: 'Spring Sprint'
    assert_no_selector 'nav.navbar'
    assert_no_selector 'footer'

    assert_selector 'h3', text: 'Course: Long Course (2 participants)'
    assert_selector 'h3', text: 'Course: Score Course (0 participants)'

    # Mary holds a current-year membership (fixture); Oscar does not
    mary = find('tr', text: 'Mary Member')
    mary.assert_text '✓'
    mary.assert_text 'Needs a ride'
    oscar = find('tr', text: 'Oscar Organizer')
    oscar.assert_no_text '✓'

    # Each course table carries blank rows for walk-up entries at the desk
    long_course_table = mary.ancestor('table')
    expected_rows = 1 + 2 + Clubsite::EventsController::NUM_BLANK_ENTRIES
    assert_equal expected_rows, long_course_table.all('tr').size
  end
end
