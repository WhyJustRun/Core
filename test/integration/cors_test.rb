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
    process :options, '/api/redactor/uploadImage', headers: { 'Origin' => 'https://evil.example' }
    assert_response :no_content
    assert_nil response.headers['Access-Control-Allow-Origin']
  end

  PUBLIC_PATHS = %w[
    /events.xml?iof_version=3.0 /events.json /club/%<club>d/events.xml?iof_version=3.0 /club/%<club>d/events.ics
    /iof/3.0/organization_list.xml /api/maps.json?min_lat=0&max_lat=1&min_lng=0&max_lng=1
  ].freeze

  test "public API endpoints on the apex allow any origin without credentials" do
    PUBLIC_PATHS.map { |path| format(path, club: Club.first.id) }.each do |path|
      get path, headers: { 'Origin' => 'https://thirdparty.example' }
      assert_equal '*', response.headers['Access-Control-Allow-Origin'], path
      assert_nil response.headers['Access-Control-Allow-Credentials'], path
      assert_includes response.headers['Vary'], 'Origin', path
    end
  end

  test "public API endpoints get the wildcard even without an Origin" do
    get '/events.xml?iof_version=3.0'
    assert_equal '*', response.headers['Access-Control-Allow-Origin']
  end

  test "allow-listed origins keep credentialed access to public endpoints" do
    get '/events.xml?iof_version=3.0', headers: { 'Origin' => 'http://cluba.test' }
    assert_equal 'http://cluba.test', response.headers['Access-Control-Allow-Origin']
    assert_equal 'true', response.headers['Access-Control-Allow-Credentials']
  end

  test "preflight on a public endpoint allows any origin to GET" do
    %w[/events.xml /iof/3.0/organization_list.xml].each do |path|
      process :options, path, headers: {
        'Origin' => 'https://thirdparty.example', 'Access-Control-Request-Method' => 'GET'
      }
      assert_response :no_content
      assert_equal '*', response.headers['Access-Control-Allow-Origin'], path
      assert_nil response.headers['Access-Control-Allow-Credentials'], path
      assert_equal 'GET, HEAD, OPTIONS', response.headers['Access-Control-Allow-Methods'], path
      assert_equal '86400', response.headers['Access-Control-Max-Age'], path
    end
  end

  test "non-public endpoints get no wildcard" do
    %w[/clubs/map /iof/3.0/users/event_list].each do |path|
      get path, headers: { 'Origin' => 'https://evil.example' }
      assert_nil response.headers['Access-Control-Allow-Origin'], path
    end

    post '/api/redactor/uploadImage', headers: { 'Origin' => 'https://evil.example' }
    assert_nil response.headers['Access-Control-Allow-Origin']

    post '/iof/3.0/events/1/result_list', headers: { 'Origin' => 'https://evil.example' }
    assert_nil response.headers['Access-Control-Allow-Origin']
  end

  test "preflight on a non-public path gets no wildcard" do
    process :options, '/api/redactor/uploadImage', headers: { 'Origin' => 'https://evil.example' }
    assert_response :no_content
    assert_nil response.headers['Access-Control-Allow-Origin']
  end

  test "club domains never get the public wildcard" do
    host! 'cluba.test'
    get '/events.xml?iof_version=3.0', headers: { 'Origin' => 'https://thirdparty.example' }
    assert_nil response.headers['Access-Control-Allow-Origin']
  end

  test "only read-only routes are flagged public" do
    flagged = Rails.application.routes.routes.select { |r| r.defaults[:public_cors] }
    assert flagged.any?
    flagged.each do |route|
      verb = route.verb
      assert_match(/\A(GET|OPTIONS)\z/, verb, "#{route.path.spec} must not be public for #{verb}")
    end
  end
end
