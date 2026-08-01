require 'test_helper'

class ClubsitePrivilegesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Only the tables this feature touches, so the test is independent of
  # fixtures belonging to other features.
  self.fixture_table_names = %w[club_categories clubs groups users privileges]

  setup do
    host! 'cluba.test'
  end

  test 'index lists only groups at or below the acting level' do
    sign_in users(:webmaster)
    get '/privileges'
    assert_response :success
    # The webmaster (90) sees the webmaster and executive groups but not the
    # administrator group (100)
    assert_select 'dt', text: 'Webmaster'
    assert_select 'dt', text: 'Executive'
    assert_select 'dt', text: 'Administrator', count: 0
    assert_select 'select[name="privilege[group_id]"] option', text: 'Administrator', count: 0
    # Members of visible groups are listed; administrator memberships are not
    assert_select 'td', text: users(:executive).name
    assert_select 'td', text: users(:admin).name, count: 0
  end

  test 'index shows all club groups to an administrator, but never global groups' do
    sign_in users(:admin)
    get '/privileges'
    assert_response :success
    assert_select 'dt', text: 'Administrator'
    assert_select 'dt', text: 'Global Administrator', count: 0
    assert_select 'select[name="privilege[group_id]"] option', text: 'Global Administrator', count: 0
  end

  test 'index redirects an executive (below the privilege edit level)' do
    sign_in users(:executive)
    get '/privileges'
    assert_redirected_to '/'
  end

  test 'index redirects signed out visitors' do
    get '/privileges'
    assert_redirected_to '/'
  end

  test 'the webmaster can grant the executive group' do
    sign_in users(:webmaster)
    assert_difference -> { Privilege.count }, 1 do
      post '/privileges/add',
           params: { privilege: { user_id: users(:member).id, group_id: groups(:cluba_executive).id } }
    end
    assert_redirected_to '/privileges/'
    assert Privilege.exists?(user_id: users(:member).id, group_id: groups(:cluba_executive).id)
  end

  test 'the webmaster cannot grant the administrator group (above their level)' do
    sign_in users(:webmaster)
    assert_no_difference -> { Privilege.count } do
      post '/privileges/add',
           params: { privilege: { user_id: users(:member).id, group_id: groups(:cluba_administrator).id } }
    end
    assert_redirected_to '/'
  end

  test 'an executive cannot grant privileges at all' do
    sign_in users(:executive)
    assert_no_difference -> { Privilege.count } do
      post '/privileges/add',
           params: { privilege: { user_id: users(:member).id, group_id: groups(:cluba_executive).id } }
    end
    assert_redirected_to '/'
  end

  test 'granting into a global group 404s' do
    sign_in users(:admin)
    assert_no_difference -> { Privilege.count } do
      post '/privileges/add',
           params: { privilege: { user_id: users(:member).id, group_id: groups(:global_administrator).id } }
    end
    assert_response :not_found
  end

  test "granting into another club's group 404s" do
    host! 'clubb.test'
    # The global admin has level 100 on clubb via the global group
    sign_in users(:global_admin)
    assert_no_difference -> { Privilege.count } do
      post '/privileges/add',
           params: { privilege: { user_id: users(:member).id, group_id: groups(:cluba_executive).id } }
    end
    assert_response :not_found
  end

  test 'a duplicate grant is a no-op' do
    sign_in users(:webmaster)
    assert_no_difference -> { Privilege.count } do
      post '/privileges/add',
           params: { privilege: { user_id: users(:executive).id, group_id: groups(:cluba_executive).id } }
    end
    assert_redirected_to '/privileges/'
  end

  test 'the webmaster can revoke an executive privilege' do
    sign_in users(:webmaster)
    assert_difference -> { Privilege.count }, -1 do
      post "/privileges/delete/#{privileges(:executive_cluba).id}"
    end
    assert_redirected_to '/privileges/'
  end

  test 'the webmaster cannot revoke an administrator privilege (above their level)' do
    sign_in users(:webmaster)
    assert_no_difference -> { Privilege.count } do
      post "/privileges/delete/#{privileges(:admin_cluba).id}"
    end
    assert_redirected_to '/'
  end

  test "revoking another club's privilege 404s" do
    host! 'clubb.test'
    sign_in users(:global_admin)
    assert_no_difference -> { Privilege.count } do
      post "/privileges/delete/#{privileges(:executive_cluba).id}"
    end
    assert_response :not_found
  end

  test 'revoking a global group privilege through a club site 404s' do
    sign_in users(:admin)
    assert_no_difference -> { Privilege.count } do
      post "/privileges/delete/#{privileges(:global_admin_global).id}"
    end
    assert_response :not_found
  end

  test 'an unprivileged member cannot revoke privileges' do
    sign_in users(:member)
    assert_no_difference -> { Privilege.count } do
      post "/privileges/delete/#{privileges(:executive_cluba).id}"
    end
    assert_redirected_to '/'
  end
end
