require 'test_helper'

# Covers the club admin CRUD pages ported from the legacy app: clubs, series,
# roles, map standards, memberships and officials.
class ClubsiteAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Only the tables these features touch, so the test is independent of
  # fixtures belonging to other features.
  self.fixture_table_names = %w[club_categories clubs groups users privileges
                                series roles memberships officials
                                official_classifications]

  setup do
    host! 'cluba.test'
  end

  # --- Clubs ---------------------------------------------------------------

  test 'clubs index is public and lists visible clubs' do
    get '/clubs'
    assert_response :success
    assert_select 'td', text: 'Club A Orienteering'
    assert_select 'td', text: 'Club B Orienteering'
    # Invisible clubs are not listed
    assert_select 'td', text: 'National Orienteering Federation', count: 0
  end

  test 'club edit renders for the webmaster' do
    sign_in users(:webmaster)
    get '/clubs/edit'
    assert_response :success
    assert_select 'form[action="/clubs/edit"]'
    assert_select 'input#club_name[value=?]', 'Club A Orienteering'
    # Timezone select offers tz database identifiers and preselects the club's
    assert_select 'select#club_timezone option[selected][value="America/Vancouver"]'
    # Marker map wiring the JS bundle expects
    assert_select '.draggable-marker-map[data-lat-element="#ClubLat"]'
    assert_select 'input#ClubLat'
  end

  test 'club edit redirects the executive' do
    sign_in users(:executive)
    get '/clubs/edit'
    assert_redirected_to '/'
  end

  test 'club update persists and transforms pasted URLs into ids' do
    sign_in users(:webmaster)
    post '/clubs/edit', params: { club: {
      name: 'Club A Orienteering',
      acronym: 'CLUBA',
      location: 'Vancouver, BC',
      facebook_page_url: 'https://www.facebook.com/clubaorienteering/',
      juicer_feed_url: 'https://www.juicer.io/feeds/clubafeed'
    } }
    assert_redirected_to '/pages/admin'
    club = clubs(:cluba).reload
    assert_equal 'Vancouver, BC', club.location
    assert_equal 'clubaorienteering', club.facebook_page_id
    assert_equal 'clubafeed', club.juicer_feed_id
  end

  test 'club update cannot be performed by the executive' do
    sign_in users(:executive)
    post '/clubs/edit', params: { club: { name: 'Hacked' } }
    assert_redirected_to '/'
    assert_equal 'Club A Orienteering', clubs(:cluba).reload.name
  end

  # --- Series --------------------------------------------------------------

  test 'series index renders for the webmaster' do
    sign_in users(:webmaster)
    get '/series'
    assert_response :success
    assert_select 'td', text: 'Wednesday Evening Series'
  end

  test 'series index redirects the executive' do
    sign_in users(:executive)
    get '/series'
    assert_redirected_to '/'
  end

  test 'series edit renders for the webmaster' do
    sign_in users(:webmaster)
    get "/series/edit/#{series(:cluba_wednesday).id}"
    assert_response :success
    assert_select 'input#series_name[value=?]', 'Wednesday Evening Series'
    # Colorpicker markup the JS bundle expects
    assert_select '.input-group.color-picker input#series_color'
  end

  test 'series edit without an id adds a new series for the club' do
    sign_in users(:webmaster)
    assert_difference -> { clubs(:cluba).series.count }, 1 do
      post '/series/edit', params: { series: {
        acronym: 'SAT', name: 'Saturday Series', color: 'rgba(0,0,255,1)', is_current: '1'
      } }
    end
    assert_redirected_to '/series/index'
    series = clubs(:cluba).series.find_by(name: 'Saturday Series')
    assert_equal 'SAT', series.acronym
  end

  test 'series update persists' do
    sign_in users(:webmaster)
    post "/series/edit/#{series(:cluba_wednesday).id}",
         params: { series: { name: 'Wednesday Night Series' } }
    assert_redirected_to '/series/index'
    assert_equal 'Wednesday Night Series', series(:cluba_wednesday).reload.name
  end

  test "another club's site cannot edit this club's series" do
    host! 'clubb.test'
    sign_in users(:global_admin)
    post "/series/edit/#{series(:cluba_wednesday).id}",
         params: { series: { name: 'Hacked' } }
    assert_response :not_found
    assert_equal 'Wednesday Evening Series', series(:cluba_wednesday).reload.name
  end

  # --- Roles ---------------------------------------------------------------

  test 'roles index renders for a plain signed-in member' do
    sign_in users(:member)
    get '/roles'
    assert_response :success
    assert_select 'td', text: 'Organizer'
    assert_select 'td', text: 'Course Planner'
  end

  test 'roles index redirects signed-out visitors' do
    get '/roles'
    assert_redirected_to '/'
  end

  test 'roles index as json returns id and name pairs for a member' do
    sign_in users(:member)
    get '/roles/index.json'
    assert_response :success
    expected = Role.order(:id).map { |role| { 'id' => role.id, 'name' => role.name } }
    assert_equal expected, response.parsed_body.sort_by { |role| role['id'] }
  end

  test 'role edit renders for a global admin' do
    sign_in users(:global_admin)
    get "/roles/edit/#{roles(:organizer).id}"
    assert_response :success
    assert_select 'input#role_name[value=?]', 'Organizer'
  end

  test 'role edit redirects the webmaster' do
    sign_in users(:webmaster)
    get '/roles/edit'
    assert_redirected_to '/'
  end

  # Roles are shared across every club, so a per-club administrator (level 100
  # at their own club, but not a global admin) may not edit them.
  test 'role edit redirects a per-club administrator' do
    sign_in users(:admin)
    get '/roles/edit'
    assert_redirected_to '/'
  end

  test 'role edit without an id adds a new role for a global admin' do
    sign_in users(:global_admin)
    assert_difference -> { Role.count }, 1 do
      post '/roles/edit', params: { role: { name: 'Controller', description: 'Controls the course' } }
    end
    assert_redirected_to '/roles/'
    assert Role.exists?(name: 'Controller')
  end

  test 'a per-club administrator cannot add a role' do
    sign_in users(:admin)
    assert_no_difference -> { Role.count } do
      post '/roles/edit', params: { role: { name: 'Controller', description: 'Controls the course' } }
    end
    assert_redirected_to '/'
  end

  # --- Map standards -------------------------------------------------------

  test 'map standards index renders for a global admin' do
    sign_in users(:global_admin)
    get '/mapStandards'
    assert_response :success
    assert_select 'h1', 'Map Standards'
  end

  test 'map standards index redirects the webmaster' do
    sign_in users(:webmaster)
    get '/mapStandards'
    assert_redirected_to '/'
  end

  # Map standards are shared across every club, so a per-club administrator may
  # not manage them.
  test 'map standards index redirects a per-club administrator' do
    sign_in users(:admin)
    get '/mapStandards'
    assert_redirected_to '/'
  end

  test 'map standard add, update and delete by a global admin' do
    sign_in users(:global_admin)
    assert_difference -> { MapStandard.count }, 1 do
      post '/mapStandards/edit', params: { map_standard: {
        name: 'ISOM 2017', color: 'rgba(0,0,0,1)', description: 'Orienteering maps'
      } }
    end
    assert_redirected_to '/mapStandards/'
    map_standard = MapStandard.find_by(name: 'ISOM 2017')

    post "/mapStandards/edit/#{map_standard.id}", params: { map_standard: { name: 'ISOM 2017-2' } }
    assert_redirected_to '/mapStandards/'
    assert_equal 'ISOM 2017-2', map_standard.reload.name

    assert_difference -> { MapStandard.count }, -1 do
      post "/mapStandards/delete/#{map_standard.id}"
    end
    assert_redirected_to '/mapStandards/'
  end

  test 'map standard delete redirects the webmaster' do
    sign_in users(:webmaster)
    assert_no_difference -> { MapStandard.count } do
      post '/mapStandards/delete/1'
    end
    assert_redirected_to '/'
  end

  test 'a per-club administrator cannot delete a map standard' do
    sign_in users(:admin)
    assert_no_difference -> { MapStandard.count } do
      post '/mapStandards/delete/1'
    end
    assert_redirected_to '/'
  end

  # --- Memberships ---------------------------------------------------------

  test 'memberships index renders for a plain signed-in member' do
    sign_in users(:member)
    get '/memberships'
    assert_response :success
    assert_select 'h3', text: 'Membership year: 2026'
    assert_select 'h3', text: 'Membership year: 2025'
    assert_select 'td', text: 'Mary Member'
    # Memberships of other clubs are not listed
    assert_select 'td', text: 'Gary Global', count: 0
  end

  test 'memberships index redirects signed-out visitors' do
    get '/memberships'
    assert_redirected_to '/'
  end

  test 'membership edit renders for the executive' do
    sign_in users(:executive)
    get "/memberships/edit/#{memberships(:cluba_member_previous).id}"
    assert_response :success
    assert_select 'input#membership_year[value=?]', '2025'
  end

  test 'membership edit redirects a plain member' do
    sign_in users(:member)
    get '/memberships/edit'
    assert_redirected_to '/'
  end

  test 'membership add, update and delete by the executive' do
    sign_in users(:executive)
    assert_difference -> { clubs(:cluba).memberships.count }, 1 do
      post '/memberships/edit', params: { membership: {
        user_id: users(:organizer).id, year: 2024, created: '2024-01-01 00:00:00'
      } }
    end
    assert_redirected_to '/memberships/'
    membership = clubs(:cluba).memberships.find_by(year: 2024)
    assert_equal users(:organizer).id, membership.user_id

    post "/memberships/edit/#{membership.id}", params: { membership: { year: 2023 } }
    assert_redirected_to '/memberships/'
    assert_equal 2023, membership.reload.year

    assert_difference -> { clubs(:cluba).memberships.count }, -1 do
      post "/memberships/delete/#{membership.id}"
    end
    assert_redirected_to '/memberships/'
  end

  test 'a plain member cannot add a membership' do
    sign_in users(:member)
    assert_no_difference -> { Membership.count } do
      post '/memberships/edit', params: { membership: { user_id: users(:member).id, year: 2024 } }
    end
    assert_redirected_to '/'
  end

  test "another club's membership cannot be deleted through this club's site" do
    sign_in users(:executive)
    assert_no_difference -> { Membership.count } do
      post "/memberships/delete/#{memberships(:clubb_global_admin).id}"
    end
    assert_response :not_found
  end

  # --- Officials -----------------------------------------------------------

  test 'officials index renders for the webmaster' do
    sign_in users(:webmaster)
    get '/officials'
    assert_response :success
    assert_select 'td', text: 'Mary Member'
    # Add form wiring the person picker JS expects
    assert_select 'form[action="/officials/add"] input#OfficialUserId'
    assert_select 'input.simple-person-picker[data-user-id-target="#OfficialUserId"]'
  end

  test 'officials index redirects the executive' do
    sign_in users(:executive)
    get '/officials'
    assert_redirected_to '/'
  end

  test 'official add, update and delete by the webmaster' do
    sign_in users(:webmaster)
    assert_difference -> { Official.count }, 1 do
      post '/officials/add', params: { official: {
        user_id: users(:organizer).id,
        official_classification_id: official_classifications(:level_two).id,
        date: '2026-07-01'
      } }
    end
    assert_redirected_to '/officials/'
    official = Official.find_by(user_id: users(:organizer).id)
    assert_equal official_classifications(:level_two).id, official.official_classification_id

    post "/officials/edit/#{official.id}", params: { official: {
      user_id: official.user_id,
      official_classification_id: official_classifications(:level_one).id,
      date: '2026-07-02'
    } }
    assert_redirected_to '/officials/'
    assert_equal official_classifications(:level_one).id, official.reload.official_classification_id

    assert_difference -> { Official.count }, -1 do
      post "/officials/delete/#{official.id}"
    end
    assert_redirected_to '/officials/'
  end

  test 'an executive cannot add an official' do
    sign_in users(:executive)
    assert_no_difference -> { Official.count } do
      post '/officials/add', params: { official: {
        user_id: users(:organizer).id,
        official_classification_id: official_classifications(:level_one).id,
        date: '2026-07-01'
      } }
    end
    assert_redirected_to '/'
  end
end
