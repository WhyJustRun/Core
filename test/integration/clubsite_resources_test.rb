require 'test_helper'

class ClubsiteResourcesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Only the tables this feature touches, so the test is independent of
  # fixtures belonging to other features.
  self.fixture_table_names = %w[club_categories clubs groups users privileges]

  setup do
    host! 'cluba.test'
  end

  teardown do
    # Remove any files written to the data volume during the test
    [clubs(:cluba), clubs(:clubb)].each do |club|
      FileUtils.rm_rf(File.join(Settings.dataFolder, club.id.to_s))
    end
  end

  test 'index renders for an executive with upload forms but no delete buttons' do
    sign_in users(:executive)
    get '/resources'
    assert_response :success
    assert_select 'strong', text: 'Header Image'
    assert_select 'strong', text: 'Logo'
    assert_select 'strong', text: 'CSS Style'
    assert_select 'form[action="/resources/add"]', count: 3
    # Deleting requires level 90
    assert_select 'form[action^="/resources/delete"]', count: 0
  end

  test 'index redirects an unprivileged member' do
    sign_in users(:member)
    get '/resources'
    assert_redirected_to '/'
  end

  test 'index redirects signed out visitors' do
    get '/resources'
    assert_redirected_to '/'
  end

  test 'uploading an image creates the DB row, the file and its thumbnails' do
    sign_in users(:executive)
    assert_difference -> { Resource.count }, 1 do
      post '/resources/add', params: {
        resource: { key: 'logo', file: fixture_file_upload('logo.png', 'image/png'), caption: 'Our logo' }
      }
    end
    assert_redirected_to '/resources/index'

    resource = Resource.find_by(club_id: clubs(:cluba).id, key: 'logo')
    assert_equal 'png', resource.extension
    assert_equal 'Our logo', resource.caption
    assert File.exist?(resource.absolute_path)
    Resource::THUMBNAIL_SIZES.each do |size|
      assert File.exist?(resource.absolute_path(size)), "expected #{size} thumbnail"
    end
    # The source is only 12px wide, so the only-shrink resize must not enlarge
    thumbnail = MiniMagick::Image.open(resource.absolute_path('2600'))
    assert_equal 12, thumbnail.width

    # The index now shows the thumbnail preview and, for the webmaster, delete buttons
    sign_in users(:webmaster)
    get '/resources'
    assert_response :success
    assert_select 'img[src*="logo_100.jpg"]'
    assert_select "form[action=?]", "/resources/delete/#{resource.id}"
  end

  test 'uploading again with the same key replaces the existing resource' do
    sign_in users(:executive)
    post '/resources/add', params: {
      resource: { key: 'logo', file: fixture_file_upload('logo.png', 'image/png') }
    }
    original = Resource.find_by(club_id: clubs(:cluba).id, key: 'logo')

    assert_no_difference -> { Resource.count } do
      post '/resources/add', params: {
        resource: { key: 'logo', file: fixture_file_upload('logo.png', 'image/png'), caption: 'Updated' }
      }
    end
    replacement = Resource.find_by(club_id: clubs(:cluba).id, key: 'logo')
    assert_not_equal original.id, replacement.id
    assert_equal 'Updated', replacement.caption
    assert File.exist?(replacement.absolute_path)
  end

  test 'an upload with a disallowed extension is rejected' do
    sign_in users(:executive)
    assert_no_difference -> { Resource.count } do
      post '/resources/add', params: {
        resource: { key: 'logo', file: fixture_file_upload('style.css', 'text/css') }
      }
    end
    assert_redirected_to '/resources/index'
    assert_match(/is not allowed/, flash[:danger])
  end

  test 'an upload without a file is rejected' do
    sign_in users(:executive)
    assert_no_difference -> { Resource.count } do
      post '/resources/add', params: { resource: { key: 'logo' } }
    end
    assert_redirected_to '/resources/index'
    assert_equal 'No file was uploaded.', flash[:danger]
  end

  test 'an unknown resource key 404s' do
    sign_in users(:executive)
    assert_no_difference -> { Resource.count } do
      post '/resources/add', params: {
        resource: { key: 'evil', file: fixture_file_upload('logo.png', 'image/png') }
      }
    end
    assert_response :not_found
  end

  test 'a stylesheet upload works and generates no thumbnails' do
    sign_in users(:executive)
    assert_difference -> { Resource.count }, 1 do
      post '/resources/add', params: {
        resource: { key: 'style', file: fixture_file_upload('style.css', 'text/css') }
      }
    end
    resource = Resource.find_by(club_id: clubs(:cluba).id, key: 'style')
    assert_equal 'css', resource.extension
    assert_not resource.thumbnailable?
    assert File.exist?(resource.absolute_path)
    Resource::THUMBNAIL_SIZES.each do |size|
      assert_not File.exist?(resource.absolute_path(size))
    end
  end

  test 'an unprivileged member cannot upload' do
    sign_in users(:member)
    assert_no_difference -> { Resource.count } do
      post '/resources/add', params: {
        resource: { key: 'logo', file: fixture_file_upload('logo.png', 'image/png') }
      }
    end
    assert_redirected_to '/'
  end

  test 'the webmaster can delete a resource, removing its files' do
    sign_in users(:webmaster)
    post '/resources/add', params: {
      resource: { key: 'logo', file: fixture_file_upload('logo.png', 'image/png') }
    }
    resource = Resource.find_by(club_id: clubs(:cluba).id, key: 'logo')

    assert_difference -> { Resource.count }, -1 do
      post "/resources/delete/#{resource.id}"
    end
    assert_redirected_to '/resources/index'
    assert_not File.exist?(resource.absolute_path)
    Resource::THUMBNAIL_SIZES.each do |size|
      assert_not File.exist?(resource.absolute_path(size))
    end
  end

  test 'an executive cannot delete a resource' do
    sign_in users(:executive)
    post '/resources/add', params: {
      resource: { key: 'logo', file: fixture_file_upload('logo.png', 'image/png') }
    }
    resource = Resource.find_by(club_id: clubs(:cluba).id, key: 'logo')

    assert_no_difference -> { Resource.count } do
      post "/resources/delete/#{resource.id}"
    end
    assert_redirected_to '/'
    assert File.exist?(resource.absolute_path)
  end

  test "another club's resource cannot be deleted through this club's site" do
    sign_in users(:webmaster)
    post '/resources/add', params: {
      resource: { key: 'logo', file: fixture_file_upload('logo.png', 'image/png') }
    }
    resource = Resource.find_by(club_id: clubs(:cluba).id, key: 'logo')

    host! 'clubb.test'
    sign_in users(:global_admin)
    assert_no_difference -> { Resource.count } do
      post "/resources/delete/#{resource.id}"
    end
    assert_response :not_found
    assert File.exist?(resource.absolute_path)
  end
end
