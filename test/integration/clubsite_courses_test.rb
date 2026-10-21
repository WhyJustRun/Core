require 'test_helper'

class ClubsiteCoursesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    host! 'cluba.test'
    @registrant = users(:member)
    @victim = users(:organizer)
    @registered_course = courses(:race_long)
    @other_course = courses(:race_score)
  end

  test 'a registrant can unregister someone from the course they registered them on' do
    sign_in @registrant
    Result.create!(course: @registered_course, user: @victim, registrant: @registrant)

    post "/courses/unregister/#{@registered_course.id}/#{@victim.id}"

    assert_not Result.exists?(course_id: @registered_course.id, user_id: @victim.id)
  end

  test 'a registration on one course cannot be used to unregister from another course' do
    sign_in @registrant
    # The registrant registered the victim on one course...
    Result.create!(course: @registered_course, user: @victim, registrant: @registrant)
    # ...but the victim's registration on a different course was made by someone else.
    foreign = Result.create!(course: @other_course, user: @victim, registrant: @victim)

    post "/courses/unregister/#{@other_course.id}/#{@victim.id}"

    assert_redirected_to '/'
    assert Result.exists?(foreign.id), 'the unrelated registration must be left intact'
  end

  test 'anyone can unregister themselves' do
    sign_in @victim
    mine = Result.create!(course: @other_course, user: @victim, registrant: @victim)

    post "/courses/unregister/#{@other_course.id}/#{@victim.id}"

    assert_not Result.exists?(mine.id)
  end

  test 'creating a fake user requires a non-blank name' do
    sign_in @registrant
    assert_no_difference -> { User.count } do
      post '/users/add', params: { userName: '   ' }
    end
    assert_response :unprocessable_entity
  end
end
