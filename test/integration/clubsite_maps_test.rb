require 'test_helper'
require 'geocoder/lookups/test'

class ClubsiteMapsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    host! 'cluba.test'
    Geocoder.configure(lookup: :test)
    Geocoder::Lookup::Test.set_default_stub(
      [{ 'latitude' => 49.31, 'longitude' => -123.11, 'address' => { 'suburb' => 'Mapville', 'city' => 'Vancouver' } }]
    )
  end

  teardown do
    Geocoder.configure(lookup: :nominatim)
  end

  test 'maps index renders the multi-marker map without edit affordances for visitors' do
    get '/maps'
    assert_response :success
    assert_select 'h1', 'Maps'
    assert_select '.multi-marker-map[data-fetch-url="/api/maps.json"]'
    assert_select 'a[href="/maps/edit"]', count: 0
  end

  test 'maps index shows edit affordances for users with the maps edit privilege' do
    sign_in users(:executive)
    get '/maps/index'
    assert_response :success
    assert_select 'a[href="/maps/edit"]'
  end

  test 'maps index embed variant renders with the embed layout' do
    get '/maps/index.embed'
    assert_response :success
    assert_select '.multi-marker-map'
    assert_select 'link[href*="clubsite_embed"]'
    assert_select 'nav.navbar', count: 0
  end

  test 'maps show renders the map details' do
    map = maps(:cluba_forest)
    # update_columns: the shared event fixture doesn't satisfy the model's
    # required series/map associations
    events(:cluba_race).update_columns(map_id: map.id)
    get "/maps/view/#{map.id}"
    assert_response :success
    assert_select 'h1', /Forest Map/
    assert_select 'td', '1:10,000'
    assert_select 'td', text: /Spring Sprint/
    assert_select 'p', 'Mapville, Vancouver'
  end

  test 'maps report lists the maps sorted by name' do
    get '/maps/report'
    assert_response :success
    assert_select 'h1', 'List of maps'
    assert_select 'a[href=?]', "/maps/view/#{maps(:cluba_forest).id}", text: 'Forest Map'
  end

  test 'maps download redirects to the file url' do
    map = maps(:cluba_forest)
    map.update!(file_url: 'https://example.com/forest.ocd')
    get "/maps/download/#{map.id}"
    assert_redirected_to 'https://example.com/forest.ocd'
  end

  test 'maps download rewrites Dropbox links to direct downloads' do
    map = maps(:cluba_forest)
    map.update!(file_url: 'https://dl.dropboxusercontent.com/s/abc123/forest.ocd')
    get "/maps/download/#{map.id}"
    assert_redirected_to 'https://dl.dropboxusercontent.com/s/abc123/forest.ocd?dl=1'
  end

  test 'maps download leaves Dropbox links with a query string untouched' do
    map = maps(:cluba_forest)
    map.update!(file_url: 'https://dl.dropboxusercontent.com/s/abc123/forest.ocd?dl=0')
    get "/maps/download/#{map.id}"
    assert_redirected_to 'https://dl.dropboxusercontent.com/s/abc123/forest.ocd?dl=0'
  end

  test 'maps download 404s when the map has no file url' do
    get "/maps/download/#{maps(:cluba_forest).id}"
    assert_response :not_found
  end

  test 'maps rendering serves the default image when no upload exists' do
    get "/maps/rendering/#{maps(:cluba_forest).id}"
    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  test 'maps rendering 404s for an invalid thumbnail size' do
    get "/maps/rendering/#{maps(:cluba_forest).id}/999x999"
    assert_response :not_found
  end

  test 'maps rendering serves the default image for a valid thumbnail with no upload' do
    get "/maps/rendering/#{maps(:cluba_forest).id}/400x600"
    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  test 'courses map serves the default image when no upload exists' do
    get "/courses/map/#{courses(:race_long).id}"
    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  test 'courses show renders the course with its results' do
    course = courses(:race_long)
    get "/courses/view/#{course.id}"
    assert_response :success
    assert_select 'h1', /Long Course/
    assert_select 'td', text: 'Mary Member'
    assert_select 'td', text: '1:00:00'
    assert_select 'td', text: 'DNF'
  end

  test 'results index renders the results for the club' do
    get '/results'
    assert_response :success
    assert_select 'h1', 'Results'
    assert_select 'td', text: 'Mary Member'
    assert_select 'td', text: /Long Course/
  end

  test 'results index paginates with page param' do
    get '/results/index', params: { page: 2 }
    assert_response :success
    assert_select 'td', text: 'Mary Member', count: 0
  end

  test 'maps from another club 404 on this domain' do
    host! 'clubb.test'
    get "/maps/view/#{maps(:cluba_forest).id}"
    assert_response :not_found
  end

  test 'map downloads from another club 404 on this domain' do
    map = maps(:cluba_forest)
    map.update!(file_url: 'https://example.com/forest.ocd')
    host! 'clubb.test'
    get "/maps/download/#{map.id}"
    assert_response :not_found
  end

  test 'courses from another club 404 on this domain' do
    host! 'clubb.test'
    get "/courses/view/#{courses(:race_long).id}"
    assert_response :not_found
  end
end
