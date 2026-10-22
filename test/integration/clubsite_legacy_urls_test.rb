require 'test_helper'

class ClubsiteLegacyUrlsTest < ActionDispatch::IntegrationTest
  setup { host! 'cluba.test' }

  test "capitalised CakePHP paths 301 to the lowercase path" do
    get '/Events/view/5'
    assert_response :moved_permanently
    assert_redirected_to 'http://cluba.test/events/view/5'
  end

  test "only the first segment is lowercased and the query is kept" do
    get '/Events/view/AbC?foo=Bar'
    assert_redirected_to 'http://cluba.test/events/view/AbC?foo=Bar'
  end

  test "unknown lowercase paths still 404" do
    get '/nonexistent/Path'
    assert_response :not_found
  end

  test "club sites serve a favicon and an apple touch icon" do
    %w[/favicon.ico /apple-touch-icon.png].each do |path|
      get path
      assert_response :success, "#{path} should be served"
    end
  end

  test "retired CakePHP sign-in handoff URLs are gone" do
    get '/users/localLogin'
    assert_response :not_found
    host! Settings.host
    get '/users/sign_in_clubsite'
    assert_response :not_found
  end
end
