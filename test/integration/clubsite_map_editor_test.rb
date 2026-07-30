require 'test_helper'

class ClubsiteMapEditorTest < ActionDispatch::IntegrationTest
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

  test 'the add form renders for an executive' do
    sign_in users(:executive)
    get '/maps/edit'
    assert_response :success
    assert_select 'h1', 'Add Map'
    assert_select 'form[action="/maps/edit"][enctype="multipart/form-data"]'
    assert_select 'input[name="map[name]"]'
    # New maps default the marker to the club location and have no
    # immediate-save update URL yet
    assert_select ".draggable-marker-map:not([data-update-url])"
    assert_select "#MapLat[value=?]", clubs(:cluba).lat.to_s
  end

  test 'the edit form renders an existing map for an executive' do
    map = maps(:cluba_forest)
    sign_in users(:executive)
    get "/maps/edit/#{map.id}"
    assert_response :success
    assert_select 'h1', 'Edit Map'
    assert_select 'input[name="map[name]"][value=?]', 'Forest Map'
    assert_select ".draggable-marker-map[data-update-url=?]", "/maps/update/#{map.id}"
  end

  test 'the edit form redirects an unprivileged member' do
    sign_in users(:member)
    get '/maps/edit'
    assert_redirected_to '/'
  end

  test 'the edit form redirects signed out visitors' do
    get "/maps/edit/#{maps(:cluba_forest).id}"
    assert_redirected_to '/'
  end

  test "another club's map cannot be edited through this club's site" do
    host! 'clubb.test'
    sign_in users(:executive)
    get "/maps/edit/#{maps(:cluba_forest).id}"
    assert_response :not_found
  end

  test 'creating a map persists it scoped to the current club' do
    sign_in users(:executive)
    assert_difference -> { Map.count }, 1 do
      post '/maps/edit', params: {
        map: { name: 'New Map', scale: '15000', lat: '49.5', lng: '-123.5' }
      }
    end
    map = Map.order(:id).last
    assert_equal clubs(:cluba).id, map.club_id
    assert_equal 'New Map', map.name
    assert_equal 15_000, map.scale
    assert_redirected_to "/maps/view/#{map.id}"
    assert_equal 'The map has been updated.', flash[:success]
  end

  test 'creating a map without a name re-renders the form' do
    sign_in users(:executive)
    assert_no_difference -> { Map.count } do
      post '/maps/edit', params: { map: { name: '' } }
    end
    assert_response :success
    assert_select 'h1', 'Add Map'
  end

  test 'an unprivileged member cannot save a map' do
    sign_in users(:member)
    assert_no_difference -> { Map.count } do
      post '/maps/edit', params: { map: { name: 'New Map' } }
    end
    assert_redirected_to '/'
  end

  test 'updating with an image upload stores the original, thumbnails and banner' do
    map = maps(:cluba_forest)
    sign_in users(:executive)
    post "/maps/edit/#{map.id}", params: {
      map: { name: 'Forest Map', image: fixture_file_upload('logo.png', 'image/png') }
    }
    assert_redirected_to "/maps/view/#{map.id}"
    assert_equal 'The map has been updated.', flash[:success]

    store = MediaStore.new(clubs(:cluba).id, 'Map')
    assert store.exists?(map.id), 'expected the original upload'
    assert store.exists?(map.id, 'image'), 'expected the normalized image'
    # Scaled thumbnails plus HiDPI doubles, including the regenerated
    # 60x60 banner crop
    %w[400x600 800x1200 50x50 100x100 60x60 120x120].each do |size|
      assert store.exists?(map.id, size), "expected #{size} thumbnail"
    end
  end

  test 'an upload with a disallowed extension is rejected' do
    map = maps(:cluba_forest)
    sign_in users(:executive)
    post "/maps/edit/#{map.id}", params: {
      map: { name: 'Forest Map', image: fixture_file_upload('style.css', 'text/css') }
    }
    assert_redirected_to "/maps/view/#{map.id}"
    assert_match(/is not allowed/, flash[:danger])
    assert_not MediaStore.new(clubs(:cluba).id, 'Map').exists?(map.id)
  end

  test 'the webmaster can delete a map, removing its files' do
    map = maps(:cluba_forest)
    sign_in users(:webmaster)
    post "/maps/edit/#{map.id}", params: {
      map: { image: fixture_file_upload('logo.png', 'image/png') }
    }
    store = MediaStore.new(clubs(:cluba).id, 'Map')
    assert store.exists?(map.id)

    assert_difference -> { Map.count }, -1 do
      post "/maps/delete/#{map.id}"
    end
    assert_redirected_to '/maps/'
    assert_not store.exists?(map.id)
    assert_not store.exists?(map.id, 'image')
    assert_not store.exists?(map.id, '400x600')
  end

  test 'an executive cannot delete a map' do
    map = maps(:cluba_forest)
    sign_in users(:executive)
    assert_no_difference -> { Map.count } do
      post "/maps/delete/#{map.id}"
    end
    assert_redirected_to '/'
  end

  test "another club's map cannot be deleted through this club's site" do
    host! 'clubb.test'
    sign_in users(:webmaster)
    assert_no_difference -> { Map.count } do
      post "/maps/delete/#{maps(:cluba_forest).id}"
    end
    assert_response :not_found
  end

  test 'update_location updates the coordinates for an executive' do
    map = maps(:cluba_forest)
    sign_in users(:executive)
    post "/maps/update/#{map.id}/49.5/-123.45"
    assert_response :success
    map.reload
    assert_in_delta 49.5, map.lat
    assert_in_delta(-123.45, map.lng)
  end

  test 'update_location redirects an unprivileged member' do
    map = maps(:cluba_forest)
    sign_in users(:member)
    post "/maps/update/#{map.id}/49.5/-123.45"
    assert_redirected_to '/'
    assert_in_delta 49.31, map.reload.lat
  end

  test "update_location 404s for another club's map" do
    host! 'clubb.test'
    sign_in users(:executive)
    post "/maps/update/#{maps(:cluba_forest).id}/49.5/-123.45"
    assert_response :not_found
  end
end
