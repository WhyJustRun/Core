require 'application_system_test_case'

class CourseRegistrationTest < ApplicationSystemTestCase
  setup do
    # Make the fixture event upcoming so registration is open
    @event = events(:cluba_race)
    @event.update!(date: 3.days.from_now, finish_date: nil)
  end

  test "a signed-in user can register and unregister themselves" do
    sign_in_to_club users(:executive)
    visit_club "/events/view/#{@event.id}"
    assert_selector 'h2', text: 'Course Registration'

    long_course = find('.course', text: 'Long Course')
    within long_course do
      click_button 'Register'
    end

    assert_text 'Registration successful!'
    long_course = find('.course', text: 'Long Course')
    within long_course do
      assert_text 'Evan Executive'
      assert_button 'Unregister'
      assert_no_button 'Register', exact_text: true
    end
    result = Result.find_by(course_id: courses(:race_long).id, user_id: users(:executive).id)
    assert_equal users(:executive).id, result.registrant_id

    within find('.course', text: 'Long Course') do
      click_button 'Unregister'
    end
    assert_text 'Unregistration successful!'
    within find('.course', text: 'Long Course') do
      assert_no_text 'Evan Executive'
      assert_button 'Register', exact_text: true
    end
    assert_not Result.exists?(course_id: courses(:race_long).id, user_id: users(:executive).id)
  end

  test "registering an existing person through the register-others picker" do
    sign_in_to_club users(:executive)
    visit_club "/events/view/#{@event.id}"

    within '.register-others' do
      select 'Score Course', from: 'RegisterOthersCourse'
    end
    fill_in 'RegisterOthersUserName', with: 'Mary'
    find('ul.typeahead li a', text: 'Mary Member').click
    find('#RegisterOthersSubmit').click

    assert_text 'Registration successful!'
    within find('.course', text: 'Score Course') do
      assert_text 'Mary Member'
    end
    result = Result.find_by(course_id: courses(:race_score).id, user_id: users(:member).id)
    assert_equal users(:executive).id, result.registrant_id
  end

  test "registering a brand-new person creates their account" do
    sign_in_to_club users(:executive)
    visit_club "/events/view/#{@event.id}"

    within '.register-others' do
      select 'Score Course', from: 'RegisterOthersCourse'
    end
    fill_in 'RegisterOthersUserName', with: 'Robin Racer'
    accept_confirm do
      find('#RegisterOthersSubmit').click
    end

    assert_text 'Registration successful!'
    within find('.course', text: 'Score Course') do
      assert_text 'Robin Racer'
    end
    new_user = User.find_by(name: 'Robin Racer')
    assert_not_nil new_user
    assert_nil new_user.email
    result = Result.find_by(course_id: courses(:race_score).id, user_id: new_user.id)
    assert_equal users(:executive).id, result.registrant_id
  end

  test "signed-out visitors are sent to the sign-in flow" do
    visit_club "/events/view/#{@event.id}"

    within '.register-others' do
      assert_link 'Sign in / Sign Up'
    end

    within find('.course', text: 'Long Course') do
      click_button 'Register'
    end
    # Registration requires sign-in; the visitor lands on the apex form
    assert_selector 'h3', text: 'Sign in'
    assert_equal Settings.host, URI.parse(current_url).host
  end

  test "closed registration hides the registration controls" do
    @event.update!(registration_deadline: 1.day.ago)
    sign_in_to_club users(:executive)
    visit_club "/events/view/#{@event.id}"

    assert_text 'Registration is Closed'
    assert_no_button 'Register', exact_text: true
    assert_no_selector '.register-others'
  end
end
