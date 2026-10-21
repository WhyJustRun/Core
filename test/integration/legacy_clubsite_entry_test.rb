require 'test_helper'

class LegacyClubsiteEntryTest < ActionDispatch::IntegrationTest
  setup do
    host! Settings.host
    @club = clubs(:cluba)
  end

  test "signed-out visitors go to the club site home" do
    get "/clubsite/#{@club.id}"
    assert_redirected_to @club.clubsite_url('/')
  end

  test "signed-in visitors go to the club site's SSO login" do
    user = users(:member)
    user.update!(password: 'password123', password_confirmation: 'password123')
    post '/users/sign_in', params: { user: { email: user.email, password: 'password123' } }

    get "/clubsite/#{@club.id}"
    assert_redirected_to @club.clubsite_url('/users/login')
  end
end
