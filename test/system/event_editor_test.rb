require 'application_system_test_case'

class EventEditorTest < ApplicationSystemTestCase
  test "creating an event with courses and an organizer through the editors" do
    sign_in_to_club users(:executive)
    visit_club '/events/edit'
    assert_selector 'h1', text: 'Add Event'

    fill_in 'EventName', with: 'Browser Test Meet'
    # The date picker fills in today's date on focus, so select-all and
    # overtype instead of a plain fill_in (which the maxlength would block)
    find('#EventDate').send_keys [:control, 'a'], '2026-09-10'
    fill_in 'EventTime', with: '18:30'
    find('#EventEventClassificationId').find(:option, text: /\ALocal/).select_option
    select 'Wednesday Evening Series', from: 'EventSeriesId'
    select 'Forest Map', from: 'EventMapId'
    fill_in 'EventDescription', with: 'A fun evening race.'

    # The organizer picker autocompletes from /users/index.json
    fill_in 'organizers', with: 'Oscar'
    find('ul.typeahead li a', text: 'Oscar Organizer').click
    within '.edit-event-organizers' do
      assert_selector 'td', text: 'Oscar Organizer'
      # The role select is populated from /roles/index.json
      find('tbody tr select').select('Course Planner')
    end

    # Two courses through the Knockout course editor
    within '.edit-event-courses' do
      click_button 'Course'
      click_button 'Course'
      rows = all('tbody tr')
      within rows[0] do
        inputs = all('input')
        inputs[0].set('Long')
        inputs[1].set('5200')
        inputs[2].set('180')
        inputs[3].set('The long loop')
      end
      within rows[1] do
        all('input')[0].set('Score')
        find('select').select('Score-O Points')
      end
    end

    click_button 'Save'

    assert_text 'The event has been updated.'
    assert_selector 'h1', text: 'Browser Test Meet'
    assert_text 'A fun evening race.'
    assert_selector 'h3', text: 'Long'
    assert_selector 'h3', text: 'Score'

    event = Event.find_by(name: 'Browser Test Meet')
    assert_not_nil event
    # 18:30 in the club's timezone (America/Vancouver)
    assert_equal Time.utc(2026, 9, 11, 1, 30), event.date
    assert_equal maps(:cluba_forest).id, event.map_id
    assert_equal series(:cluba_wednesday).id, event.series_id
    assert_equal 4, event.event_classification_id

    assert_equal %w[Long Score], event.courses.map(&:name).sort
    long_course = event.courses.find_by(name: 'Long')
    assert_equal 5200, long_course.distance
    assert_equal 180, long_course.climb
    assert_equal 'The long loop', long_course.description
    assert_not long_course.is_score_o
    assert event.courses.find_by(name: 'Score').is_score_o

    assert_equal 1, event.organizers.count
    organizer = event.organizers.first
    assert_equal users(:organizer).id, organizer.user_id
    assert_equal roles(:course_planner).id, organizer.role_id
  end

  test "editing an event rehydrates the editors and persists changes" do
    event = events(:cluba_race)
    score_course_id = courses(:race_score).id
    sign_in_to_club users(:executive)
    visit_club "/events/edit/#{event.id}"
    assert_selector 'h1', text: 'Edit Event'

    # The organizer editor rehydrates from the JSON blob, with the stored role
    within '.edit-event-organizers' do
      assert_selector 'td', text: 'Oscar Organizer'
      selected_role = find('tbody tr select').all('option').detect(&:selected?)
      assert_equal 'Organizer', selected_role.text
    end

    within '.edit-event-courses' do
      assert_selector 'tbody tr', count: 2
      names = all('tbody tr td:first-child input').map(&:value)
      assert_equal ['Long Course', 'Score Course'], names.sort

      # Update the long course in place
      long_row = all('tbody tr').detect { |row| row.first('input').value == 'Long Course' }
      within long_row do
        inputs = all('input')
        inputs[0].set('Longer Course')
        inputs[1].set('6000')
      end

      # Delete the score course; this posts to /courses/delete immediately
      score_row = all('tbody tr').detect { |row| row.first('input').value == 'Score Course' }
      accept_confirm do
        score_row.find('button').click
      end
      assert_selector 'tbody tr', count: 1
    end
    wait_for_condition(message: 'course was not deleted') { !Course.exists?(score_course_id) }

    within '.edit-event-organizers' do
      find('tbody tr select').select('Course Planner')
    end

    click_button 'Save'
    assert_text 'The event has been updated.'

    assert_equal ['Longer Course'], event.reload.courses.map(&:name)
    assert_equal 6000, courses(:race_long).reload.distance
    assert_equal [roles(:course_planner).id], event.organizers.map(&:role_id)
  end
end
