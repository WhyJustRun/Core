require 'application_system_test_case'

class ResultsEditorTest < ApplicationSystemTestCase
  test "entering results and adding a new person persists on save" do
    event = events(:cluba_race)
    sign_in_to_club users(:executive)
    visit_club "/events/editResults/#{event.id}"

    # The editor loads its data from the event JSON
    assert_selector 'h2', text: 'Long Course'
    assert_selector 'h2', text: 'Score Course'
    assert_selector 'td', text: 'Mary Member'

    # Enter a time and status for the existing registrant
    within find('tr', text: 'Mary Member') do
      segments = all('input.time-segment')
      segments[0].set('01')
      segments[1].set('05')
      segments[2].set('30')
      find('select').select('DSQ')
    end

    # Add a brand-new person (the fake-user path) to the long course
    find('select[data-bind*="selectedCourse"]').select('Long Course')
    fill_in 'competitorResults', with: 'Nellie Newbie'
    find('ul.typeahead li a', text: 'Create New User (Nellie Newbie)').click
    assert_selector 'td', text: 'Nellie Newbie'

    click_button 'Save'

    # Saving posts the JSON blob and redirects to the event page
    assert_selector 'h1', text: 'Spring Sprint'
    result = results(:member_long).reload
    assert_in_delta 3930.0, result.time_seconds
    assert_equal :disqualified, result.status
    assert events(:cluba_race).reload.results_posted

    new_user = User.find_by(name: 'Nellie Newbie')
    assert_not_nil new_user
    assert_nil new_user.email
    new_result = Result.find_by(user_id: new_user.id, course_id: courses(:race_long).id)
    assert_not_nil new_result
    assert_equal :ok, new_result.status
  end

  test "deleting a result removes it immediately over AJAX" do
    event = events(:cluba_race)
    result = results(:organizer_long)
    sign_in_to_club users(:executive)
    visit_club "/events/editResults/#{event.id}"

    assert_selector 'td', text: 'Oscar Organizer'
    accept_confirm do
      find('tr', text: 'Oscar Organizer').find('button').click
    end
    assert_no_selector 'td', text: 'Oscar Organizer'
    wait_for_condition(message: 'result was not deleted') { !Result.exists?(result.id) }

    # The deletion survives a reload
    visit_club "/events/editResults/#{event.id}"
    assert_selector 'td', text: 'Mary Member'
    assert_no_selector 'td', text: 'Oscar Organizer'
  end
end
