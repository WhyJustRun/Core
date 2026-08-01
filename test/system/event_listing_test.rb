require 'application_system_test_case'

class EventListingTest < ApplicationSystemTestCase
  test "the event listing populates from the IOF XML feed" do
    events(:cluba_training).update!(date: 1.week.from_now)
    events(:cluba_race).update!(date: 3.weeks.from_now, finish_date: nil)

    visit_club '/events/listing'

    assert_selector '.event-box', text: 'Evening Training'
    assert_selector '.event-box', text: 'Spring Sprint'
    within find('.event-box', text: 'Evening Training') do
      assert_selector '.event-box-classification', text: 'Club'
    end
    assert_text(/Showing events after/)
  end

  test "the Older button extends the window backwards" do
    Event.create!(name: 'Autumn Classic', club: clubs(:cluba),
                  event_classification: event_classifications(:local),
                  date: 3.months.ago)

    visit_club '/events/listing'
    assert_selector '.event-list'
    assert_no_selector '.event-box', text: 'Autumn Classic'

    click_button 'Older'
    assert_selector '.event-box', text: 'Autumn Classic'
  end

  test "the home page event list populates from the feed" do
    events(:cluba_training).update!(date: 1.week.from_now)

    visit_club '/'
    assert_selector '.event-box', text: 'Evening Training'
  end
end
