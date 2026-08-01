require 'test_helper'

class RedactorUploadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # organizer has an Organizer row, so RedactorPolicy#store_file? passes
    sign_in users(:organizer)
  end

  test 'upload_file stores an allowlisted extension' do
    post '/api/redactor/uploadFile',
         params: { file: fixture_file_upload('redactor_sample.png', 'image/png') }
    assert_response :success
    assert JSON.parse(response.body)['filelink'].present?
  end

  test 'upload_file rejects an html file even with a spoofed image content-type' do
    post '/api/redactor/uploadFile',
         params: { file: fixture_file_upload('redactor_sample.html', 'image/png') }
    assert_response :success
    assert_nil JSON.parse(response.body)['filelink']
  end

  test 'upload_file rejects an svg file' do
    post '/api/redactor/uploadFile',
         params: { file: fixture_file_upload('redactor_sample.svg', 'image/svg+xml') }
    assert_response :success
    assert_nil JSON.parse(response.body)['filelink']
  end

  test 'upload_image accepts a png' do
    post '/api/redactor/uploadImage',
         params: { file: fixture_file_upload('redactor_sample.png', 'image/png') }
    assert_response :success
    assert JSON.parse(response.body)['filelink'].present?
  end

  test 'upload_image rejects a non-image extension' do
    post '/api/redactor/uploadImage',
         params: { file: fixture_file_upload('redactor_sample.html', 'image/png') }
    assert_response :success
    assert_nil JSON.parse(response.body)['filelink']
  end

  test 'redactor uploads require sign-in' do
    sign_out :user
    post '/api/redactor/uploadImage',
         params: { file: fixture_file_upload('redactor_sample.png', 'image/png') }
    assert_response :redirect
  end
end
