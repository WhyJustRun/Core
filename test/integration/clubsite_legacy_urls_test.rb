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
end
