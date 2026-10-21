require 'test_helper'

class ClubsiteSsoTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:member)
    @user.update!(password: 'password123', password_confirmation: 'password123')
  end

  def apex_sign_in
    host! Settings.host
    post '/users/sign_in', params: { user: { email: @user.email, password: 'password123' } }
  end

  test "club sign-in link starts the apex authorize flow" do
    host! 'cluba.test'
    get '/users/login'
    assert_response :redirect
    assert_match %r{/sso/authorize\?return_host=cluba\.test}, response.headers['Location']
  end

  test "full handoff signs the user in on the club domain" do
    apex_sign_in

    get '/sso/authorize', params: { return_host: 'cluba.test', return_path: '/events/listing' }
    location = response.headers['Location']
    assert_match %r{\Ahttps://cluba\.test/sso/consume\?}, location

    query = Rack::Utils.parse_query(URI.parse(location).query)
    host! 'cluba.test'
    get '/sso/consume', params: { token: query['token'], path: query['path'] }
    assert_redirected_to '/events/listing'

    get '/'
    assert_select 'a', text: 'Sign out'
  end

  test "signing in through the apex form continues to the club" do
    host! 'cluba.test'
    get '/users/login'

    host! Settings.host
    get '/sso/authorize', params: { return_host: 'cluba.test' }
    assert_redirected_to '/users/sign_in'

    post '/users/sign_in', params: { user: { email: @user.email, password: 'password123' } }
    assert_match %r{/sso/authorize\?return_host=cluba\.test}, response.headers['Location']
  end

  test "expired tokens are rejected" do
    apex_sign_in
    get '/sso/authorize', params: { return_host: 'cluba.test' }
    query = Rack::Utils.parse_query(URI.parse(response.headers['Location']).query)

    travel 2.minutes do
      host! 'cluba.test'
      get '/sso/consume', params: { token: query['token'] }
      assert_redirected_to '/'
      follow_redirect!
      assert_select 'a', text: 'Sign in/Sign up'
    end
  end

  test "tokens are bound to the club host" do
    apex_sign_in
    get '/sso/authorize', params: { return_host: 'cluba.test' }
    query = Rack::Utils.parse_query(URI.parse(response.headers['Location']).query)

    host! 'clubb.test'
    get '/sso/consume', params: { token: query['token'] }
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'a', text: 'Sign in/Sign up'
  end

  test "authorize rejects hosts that are not club domains" do
    apex_sign_in
    get '/sso/authorize', params: { return_host: 'evil.example.com' }
    assert_redirected_to '/'
  end

  test "consume only redirects to relative paths" do
    apex_sign_in
    get '/sso/authorize', params: { return_host: 'cluba.test' }
    query = Rack::Utils.parse_query(URI.parse(response.headers['Location']).query)

    host! 'cluba.test'
    get '/sso/consume', params: { token: query['token'], path: '//evil.example.com/x' }
    assert_redirected_to '/'
  end

  test "signing out ends both sessions" do
    apex_sign_in
    get '/sso/authorize', params: { return_host: 'cluba.test' }
    query = Rack::Utils.parse_query(URI.parse(response.headers['Location']).query)
    host! 'cluba.test'
    get '/sso/consume', params: { token: query['token'] }

    get '/users/logout'
    assert_match %r{/sso/logout\?return_host=cluba\.test}, response.headers['Location']

    host! Settings.host
    get '/sso/logout', params: { return_host: 'cluba.test' }
    assert_redirected_to 'https://cluba.test/users/logoutComplete'

    host! 'cluba.test'
    get '/users/logoutComplete'
    assert_redirected_to '/'
    get '/'
    assert_select 'a', text: 'Sign in/Sign up'

    host! Settings.host
    get '/'
    assert_select 'a[href=?]', '/users/sign_in', minimum: 0
  end

  test "legacy register and profile URLs redirect to the apex" do
    host! 'cluba.test'
    get '/users/register'
    assert_response :moved_permanently
    assert_match %r{/users/sign_up\z}, response.headers['Location']

    get "/users/view/#{@user.id}"
    assert_response :moved_permanently
    assert_match %r{/users/#{@user.id}\z}, response.headers['Location']
  end
end
