require 'test_helper'

class ClubsiteProbeRequestsTest < ActionDispatch::IntegrationTest
  setup do
    host! 'cluba.test'
    @forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown { ActionController::Base.allow_forgery_protection = @forgery_protection }

  test "POSTs to unknown paths 404 instead of failing CSRF" do
    post '/wp-admin/admin-ajax.php', params: { action: 'the_grid_load_more', grid_nonce: '0' }
    assert_response :not_found
  end

  test "real endpoints still enforce CSRF" do
    post '/pages/add', params: { page: { name: 'x' } }
    assert_response :unprocessable_entity
  end
end
