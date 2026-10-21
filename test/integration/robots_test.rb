require 'test_helper'

class RobotsTest < ActionDispatch::IntegrationTest
  test "visible clubs allow crawlers" do
    host! 'cluba.test'
    get '/robots.txt'
    assert_response :success
    assert_equal "User-agent: *\nDisallow:\n", response.body
  end

  test "invisible clubs are hidden from crawlers" do
    host! 'federation.test'
    get '/robots.txt'
    assert_response :success
    assert_equal "User-agent: *\nDisallow: /\n", response.body
  end

  test "apex robots.txt allows crawling" do
    host! Settings.host
    get '/robots.txt'
    assert_response :success
    assert_no_match(/^Disallow: \//, response.body)
  end
end
