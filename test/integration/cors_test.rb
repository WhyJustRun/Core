require 'test_helper'

class CorsTest < ActionDispatch::IntegrationTest
  setup { host! Settings.host }

  test "club domains may make credentialed cross-origin requests" do
    get '/clubs/map', headers: { 'Origin' => 'http://cluba.test' }
    assert_equal 'http://cluba.test', response.headers['Access-Control-Allow-Origin']
    assert_equal 'true', response.headers['Access-Control-Allow-Credentials']
    assert_includes response.headers['Vary'], 'Origin'
  end

  test "unknown origins get no CORS headers" do
    get '/clubs/map', headers: { 'Origin' => 'https://evil.example' }
    assert_nil response.headers['Access-Control-Allow-Origin']
    assert_nil response.headers['Access-Control-Allow-Credentials']
  end

  test "requests without an Origin get no CORS headers" do
    get '/clubs/map'
    assert_nil response.headers['Access-Control-Allow-Origin']
  end

  test "malformed origins are rejected without raising" do
    get '/clubs/map', headers: { 'Origin' => 'http://bad host' }
    assert_nil response.headers['Access-Control-Allow-Origin']
  end

  test "preflight from a club domain is answered with the allowed methods" do
    process :options, '/iof/3.0/events/1/result_list.xml', headers: {
      'Origin' => 'http://cluba.test', 'Access-Control-Request-Method' => 'GET'
    }
    assert_response :no_content
    assert_equal 'http://cluba.test', response.headers['Access-Control-Allow-Origin']
    assert_includes response.headers['Access-Control-Allow-Methods'], 'GET'
    assert_equal '86400', response.headers['Access-Control-Max-Age']
  end

  test "preflight from an unknown origin is answered without allowing it" do
    process :options, '/iof/3.0/events/1/result_list.xml', headers: { 'Origin' => 'https://evil.example' }
    assert_response :no_content
    assert_nil response.headers['Access-Control-Allow-Origin']
  end
end
