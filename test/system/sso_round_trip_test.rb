require 'application_system_test_case'

class SsoRoundTripTest < ApplicationSystemTestCase
  test "the club sign-in link goes through the apex form and returns signed in" do
    user = users(:member)
    user.update!(password: 'password123', password_confirmation: 'password123')

    visit_club '/'
    click_link 'Sign in/Sign up'

    # Sent to the sign-in form on the apex domain
    assert_selector 'h3', text: 'Sign in'
    assert_equal Settings.host, URI.parse(current_url).host

    within "form[action='/users/sign_in']" do
      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'password123'
      click_button 'Sign in'
    end

    # ... and handed back to the club domain with a signed-in session
    assert_selector 'a', text: 'Sign out'
    assert_equal clubs(:cluba).domain, URI.parse(current_url).host
    assert_selector 'header h1', text: 'Club A Orienteering'
  end

  test "an existing apex session carries over to the club domain" do
    sign_in_to_club users(:member)
    assert_no_selector 'a', text: 'Sign in/Sign up'
  end

  test "signing out on the club domain ends both sessions" do
    sign_in_to_club users(:member)

    click_link 'Sign out'
    assert_text 'You have been signed out.'
    assert_equal clubs(:cluba).domain, URI.parse(current_url).host
    assert_selector 'a', text: 'Sign in/Sign up'

    # The apex session is gone too
    visit_apex '/'
    assert_link 'Sign up'
    assert_no_selector 'a', text: 'Sign out'
  end
end
