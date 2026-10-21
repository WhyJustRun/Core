require 'test_helper'

class ClubsiteRegistrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    host! 'cluba.test'
  end

  teardown do
    # Remove any files written to the data volume during the test
    [clubs(:cluba), clubs(:clubb)].each do |club|
      FileUtils.rm_rf(File.join(Settings.dataFolder, club.id.to_s))
    end
  end

  # --- Registration ---

  test 'a signed-in user can register themselves' do
    sign_in users(:executive)
    course = courses(:race_score)
    assert_difference -> { Result.count }, 1 do
      post "/courses/register/#{course.id}/0"
    end
    assert_redirected_to "/events/view/#{course.event_id}"
    result = Result.find_by(course_id: course.id, user_id: users(:executive).id)
    assert_equal users(:executive).id, result.registrant_id
  end

  test 'registering someone else records the current user as the registrant' do
    sign_in users(:executive)
    course = courses(:race_score)
    assert_difference -> { Result.count }, 1 do
      post "/courses/register/#{course.id}/#{users(:member).id}"
    end
    assert_redirected_to "/events/view/#{course.event_id}"
    result = Result.find_by(course_id: course.id, user_id: users(:member).id)
    assert_equal users(:executive).id, result.registrant_id
  end

  test 'registering a freshly added fake user' do
    sign_in users(:member)
    post '/users/add', params: { userName: 'Nora Newcomer' }
    assert_response :success
    new_user_id = JSON.parse(response.body)
    new_user = User.find(new_user_id)
    assert_equal 'Nora Newcomer', new_user.name
    assert_nil new_user.email

    course = courses(:race_score)
    assert_difference -> { Result.count }, 1 do
      post "/courses/register/#{course.id}/#{new_user_id}"
    end
    assert_redirected_to "/events/view/#{course.event_id}"
    result = Result.find_by(course_id: course.id, user_id: new_user_id)
    assert_equal users(:member).id, result.registrant_id
  end

  test 'a duplicate registration is a silent no-op' do
    sign_in users(:member)
    course = courses(:race_long)
    assert_no_difference -> { Result.count } do
      post "/courses/register/#{course.id}"
    end
    assert_redirected_to "/events/view/#{course.event_id}"
    assert_nil flash[:success]
  end

  test 'registration requires sign-in' do
    assert_no_difference -> { Result.count } do
      post "/courses/register/#{courses(:race_long).id}"
    end
    assert_redirected_to '/users/login'
  end

  # --- Unregistration ---

  test 'a user can unregister themselves' do
    sign_in users(:member)
    course = courses(:race_long)
    own_result_id = results(:member_long).id
    other_result_id = results(:organizer_long).id
    assert_difference -> { Result.count }, -1 do
      post "/courses/unregister/#{course.id}"
    end
    assert_redirected_to "/events/view/#{course.event_id}"
    assert_not Result.exists?(own_result_id)
    # The other result on the course is untouched
    assert Result.exists?(other_result_id)
  end

  test 'you can unregister someone whose registration you made' do
    # The member registered the organizer (organizer_long.registrant is member)
    sign_in users(:member)
    course = courses(:race_long)
    result_id = results(:organizer_long).id
    assert_difference -> { Result.count }, -1 do
      post "/courses/unregister/#{course.id}/#{users(:organizer).id}"
    end
    assert_redirected_to "/events/view/#{course.event_id}"
    assert_not Result.exists?(result_id)
  end

  test 'you cannot unregister someone you did not register' do
    sign_in users(:executive)
    assert_no_difference -> { Result.count } do
      post "/courses/unregister/#{courses(:race_long).id}/#{users(:member).id}"
    end
    assert_redirected_to '/'
  end

  test 'unregistration requires sign-in' do
    assert_no_difference -> { Result.count } do
      post "/courses/unregister/#{courses(:race_long).id}"
    end
    assert_redirected_to '/users/login'
  end

  # --- Course deletion ---

  test 'an organizer can delete a course along with its results' do
    sign_in users(:organizer)
    course = courses(:race_long)
    assert_difference({ -> { Course.count } => -1, -> { Result.count } => -2 }) do
      post "/courses/delete/#{course.id}"
    end
    assert_response :success
  end

  test 'an unprivileged member cannot delete a course' do
    sign_in users(:member)
    assert_no_difference -> { Course.count } do
      post "/courses/delete/#{courses(:race_long).id}"
    end
    assert_redirected_to '/'
  end

  test 'course deletion redirects signed out visitors' do
    assert_no_difference -> { Course.count } do
      post "/courses/delete/#{courses(:race_long).id}"
    end
    assert_redirected_to '/'
  end

  # --- Course map upload ---

  test 'an organizer can upload a course map' do
    sign_in users(:organizer)
    course = courses(:race_long)
    post "/courses/uploadMap/#{course.id}", params: { file: fixture_file_upload('logo.png', 'image/png') }
    assert_redirected_to "/events/uploadMaps/#{course.event_id}"
    assert_equal 'Course map uploaded!', flash[:success]
    assert MediaStore.new(clubs(:cluba).id, 'Course').exists?(course.id)
  end

  test 'a disallowed file type flashes the store error and stores nothing' do
    sign_in users(:organizer)
    course = courses(:race_long)
    post "/courses/uploadMap/#{course.id}", params: { file: fixture_file_upload('style.css', 'text/css') }
    assert_redirected_to "/events/uploadMaps/#{course.event_id}"
    assert_match(/not allowed/, flash[:alert])
    assert_not MediaStore.new(clubs(:cluba).id, 'Course').exists?(course.id)
  end

  test 'uploading without a file flashes an error' do
    sign_in users(:organizer)
    course = courses(:race_long)
    post "/courses/uploadMap/#{course.id}"
    assert_redirected_to "/events/uploadMaps/#{course.event_id}"
    assert_equal 'No file selected!', flash[:alert]
  end

  test 'an unprivileged member cannot upload a course map' do
    sign_in users(:member)
    course = courses(:race_long)
    post "/courses/uploadMap/#{course.id}", params: { file: fixture_file_upload('logo.png', 'image/png') }
    assert_redirected_to "/events/view/#{course.event_id}"
    assert_not MediaStore.new(clubs(:cluba).id, 'Course').exists?(course.id)
  end

  # --- Registrant comments ---

  test 'the registrant can edit the registrant comment' do
    # The member registered the organizer's entry
    sign_in users(:member)
    result = results(:organizer_long)
    post '/results/editRegistrantComment',
         params: { result: { id: result.id, registrant_comment: 'Need a ride' } }
    assert_redirected_to "/events/view/#{courses(:race_long).event_id}"
    assert_equal 'Need a ride', result.reload.registrant_comment
  end

  test 'the registered user can edit their own comment' do
    sign_in users(:organizer)
    result = results(:organizer_long)
    post '/results/editRegistrantComment',
         params: { result: { id: result.id, registrant_comment: 'Offering a ride' } }
    assert_redirected_to "/events/view/#{courses(:race_long).event_id}"
    assert_equal 'Offering a ride', result.reload.registrant_comment
  end

  test 'a stranger cannot edit the comment' do
    sign_in users(:executive)
    result = results(:member_long)
    post '/results/editRegistrantComment',
         params: { result: { id: result.id, registrant_comment: 'nope' } }
    assert_redirected_to '/'
    assert_nil result.reload.registrant_comment
  end

  test 'comment editing requires sign-in' do
    result = results(:member_long)
    post '/results/editRegistrantComment',
         params: { result: { id: result.id, registrant_comment: 'nope' } }
    assert_redirected_to '/users/login'
    assert_nil result.reload.registrant_comment
  end

  # --- Result deletion ---

  test 'an organizer can delete a result' do
    sign_in users(:organizer)
    assert_difference -> { Result.count }, -1 do
      post "/results/delete/#{results(:member_long).id}"
    end
    assert_response :success
  end

  test 'an unprivileged member cannot delete a result' do
    sign_in users(:member)
    assert_no_difference -> { Result.count } do
      post "/results/delete/#{results(:member_long).id}"
    end
    assert_redirected_to '/'
  end

  # --- Tenancy ---

  test "acting on another club's data 404s" do
    host! 'clubb.test'

    # A request that 404s does not persist the test sign-in, so sign in
    # before each request.
    assert_no_difference -> { Result.count } do
      sign_in users(:admin)
      post "/courses/register/#{courses(:race_long).id}"
      assert_response :not_found

      sign_in users(:admin)
      post "/courses/unregister/#{courses(:race_long).id}"
      assert_response :not_found

      sign_in users(:admin)
      post "/results/delete/#{results(:member_long).id}"
      assert_response :not_found
    end

    assert_no_difference -> { Course.count } do
      sign_in users(:admin)
      post "/courses/delete/#{courses(:race_long).id}"
      assert_response :not_found
    end

    sign_in users(:admin)
    post "/courses/uploadMap/#{courses(:race_long).id}",
         params: { file: fixture_file_upload('logo.png', 'image/png') }
    assert_response :not_found
  end
end
