require 'test_helper'

class ClubsiteUsersAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    host! 'cluba.test'
  end

  # --- Autocomplete ---

  test 'autocomplete requires sign-in' do
    get '/users/index.json', params: { term: 'Mary' }
    assert_response :unauthorized
  end

  test 'autocomplete filters by term and returns the expected shape' do
    sign_in users(:member)
    get '/users/index.json', params: { term: 'Mary' }
    assert_response :success
    entries = JSON.parse(response.body)
    assert_equal 1, entries.length
    assert_equal(
      { 'name' => 'Mary Member', 'identifiableName' => 'Mary Member', 'id' => users(:member).id },
      entries.first
    )
  end

  test 'autocomplete without a term returns an empty list' do
    sign_in users(:member)
    get '/users/index.json'
    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test 'autocomplete allowFake=false hides users without an email' do
    sign_in users(:member)
    fake = User.create_fake('Frankie Fake')

    get '/users/index.json', params: { term: 'Frankie' }
    assert_includes JSON.parse(response.body).map { |entry| entry['id'] }, fake.id

    get '/users/index.json', params: { term: 'Frankie', allowFake: 'false' }
    assert_equal [], JSON.parse(response.body)
  end

  # --- Adding fake users ---

  test 'add creates a fake user and returns its id' do
    sign_in users(:member)
    assert_difference -> { User.count }, 1 do
      post '/users/add', params: { userName: 'Paula Person' }
    end
    assert_response :success
    user = User.find(JSON.parse(response.body))
    assert_equal 'Paula Person', user.name
    assert_nil user.email
    assert_not user.has_password?
  end

  test 'add requires sign-in' do
    assert_no_difference -> { User.count } do
      post '/users/add', params: { userName: 'Paula Person' }
    end
    assert_redirected_to '/users/login'
  end

  # --- Merging ---

  test 'merge re-points associations, fills blank target fields and destroys the source' do
    sign_in users(:webmaster)
    target = users(:member)
    source = User.create_fake('Mary Member')
    source.update_columns(year_of_birth: 1980, si_number: 123_456, referred_from: 'a friend',
                          club_id: clubs(:clubb).id)
    membership = Membership.create!(user_id: source.id, club: clubs(:clubb), year: 2024)
    organizer_row = Organizer.create!(user_id: source.id, event: events(:cluba_training), role: roles(:organizer))
    result_row = Result.create!(user_id: source.id, course: courses(:race_score), registrant_id: source.id)
    privilege_row = Privilege.create!(user_id: source.id, user_group: groups(:cluba_executive))

    assert_difference -> { User.count }, -1 do
      post "/users/merge/#{target.id}/#{source.id}"
    end
    assert_redirected_to '/users/showDuplicates'
    assert_not User.exists?(source.id)

    target.reload
    # Blank target fields are filled from the source
    assert_equal 1980, target.year_of_birth
    assert_equal 123_456, target.si_number
    assert_equal 'a friend', target.referred_from
    # Populated target fields win
    assert_equal 'member@example.com', target.email
    assert_equal clubs(:cluba).id, target.club_id

    # Associated rows now point at the target
    assert_equal target.id, membership.reload.user_id
    assert_equal target.id, organizer_row.reload.user_id
    assert_equal target.id, result_row.reload.user_id
    assert_equal target.id, result_row.registrant_id
    assert_equal target.id, privilege_row.reload.user_id
  end

  test 'merge requires the merge privilege' do
    sign_in users(:executive)
    source = User.create_fake('Mary Member')
    assert_no_difference -> { User.count } do
      post "/users/merge/#{users(:member).id}/#{source.id}"
    end
    assert_redirected_to '/'
    assert User.exists?(source.id)
  end

  test 'merge requires sign-in' do
    source = User.create_fake('Mary Member')
    assert_no_difference -> { User.count } do
      post "/users/merge/#{users(:member).id}/#{source.id}"
    end
    assert_redirected_to '/users/login'
  end

  test 'the merge privilege is club-scoped' do
    host! 'clubb.test'
    sign_in users(:webmaster)
    source = User.create_fake('Mary Member')
    assert_no_difference -> { User.count } do
      post "/users/merge/#{users(:member).id}/#{source.id}"
    end
    assert_redirected_to '/'
  end

  test 'a club webmaster cannot merge a global admin into another account' do
    sign_in users(:webmaster)
    assert_no_difference -> { User.count } do
      post "/users/merge/#{users(:member).id}/#{users(:global_admin).id}"
    end
    assert User.exists?(users(:global_admin).id)
  end

  test 'even a club administrator cannot merge a global admin (no cross-club privilege theft)' do
    # The club admin passes can_merge_any_user?, so only the global-admin guard
    # stops the merge -- this is the CRITICAL escalation path.
    sign_in users(:admin)
    assert_no_difference -> { User.count } do
      post "/users/merge/#{users(:admin).id}/#{users(:global_admin).id}"
    end
    assert User.exists?(users(:global_admin).id)
    assert_equal 0, users(:admin).global_privilege_level
  end

  test 'a club webmaster cannot merge accounts unrelated to their club' do
    sign_in users(:webmaster)
    target = User.create_fake('Unrelated One')
    source = User.create_fake('Unrelated Two')
    target.update_columns(club_id: clubs(:clubb).id)
    source.update_columns(club_id: clubs(:clubb).id)

    assert_no_difference -> { User.count } do
      post "/users/merge/#{target.id}/#{source.id}"
    end
    assert User.exists?(source.id)
  end

  test 'a global admin may merge accounts unrelated to any single club' do
    sign_in users(:global_admin)
    target = User.create_fake('Unrelated One')
    source = User.create_fake('Unrelated Two')
    target.update_columns(club_id: clubs(:clubb).id)
    source.update_columns(club_id: clubs(:clubb).id)

    assert_difference -> { User.count }, -1 do
      post "/users/merge/#{target.id}/#{source.id}"
    end
    assert_not User.exists?(source.id)
  end

  # --- Show duplicates ---

  test 'showDuplicates requires the merge privilege' do
    sign_in users(:executive)
    get '/users/showDuplicates'
    assert_redirected_to '/'
  end

  test 'showDuplicates requires sign-in' do
    get '/users/showDuplicates'
    assert_redirected_to '/users/login'
  end

  test 'showDuplicates lists detected duplicates with merge buttons' do
    sign_in users(:webmaster)
    duplicate = User.create_fake('Mary Member')
    get '/users/showDuplicates'
    assert_response :success
    assert_select 'h1', 'Merge user accounts'
    # The member has results at a cluba event, so they are the primary
    assert_select "form[action='/users/merge/#{users(:member).id}/#{duplicate.id}']"
    # The webmaster (90) is below the user edit level, so no manual merge form
    assert_select "select[name='user[0][user_id]']", count: 0
  end

  test 'an admin sees the manual merge form and can merge two picked users' do
    sign_in users(:admin)
    duplicate = User.create_fake('Extra Person')
    target = users(:member)

    get '/users/showDuplicates'
    assert_response :success
    assert_select "select[name='user[0][user_id]']"
    assert_select "select[name='user[1][user_id]']"

    assert_difference -> { User.count }, -1 do
      post '/users/showDuplicates',
           params: { user: { '0' => { user_id: target.id }, '1' => { user_id: duplicate.id } } }
    end
    assert_redirected_to '/users/showDuplicates'
    assert_not User.exists?(duplicate.id)
  end

  test 'picking the same user twice does not merge' do
    sign_in users(:admin)
    assert_no_difference -> { User.count } do
      post '/users/showDuplicates',
           params: { user: { '0' => { user_id: users(:member).id }, '1' => { user_id: users(:member).id } } }
    end
    assert_redirected_to '/users/showDuplicates'
    assert User.exists?(users(:member).id)
  end
end
