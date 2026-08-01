require 'application_system_test_case'

class PasswordResetTest < ApplicationSystemTestCase
  setup do
    # The mail initializer configures SMTP delivery for every environment;
    # capture deliveries in memory for the duration of this test instead.
    @original_delivery_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    ActionMailer::Base.delivery_method = @original_delivery_method
  end

  test "resetting a password through the emailed link" do
    user = users(:member)
    user.update!(password: 'old-password-1', password_confirmation: 'old-password-1')

    visit_apex '/users/sign_in'
    within "form[action='/users/password']" do
      fill_in 'user[email]', with: user.email
      click_button 'Reset password'
    end
    assert_text 'you will receive a password recovery link'

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail, 'no reset mail was sent'
    assert_equal [user.email], mail.to

    link = mail.body.to_s[%r{http://[^"]+reset_password_token=[^"]+}]
    assert_not_nil link, 'reset link missing from the mail body'

    visit link
    assert_selector 'h2', text: 'Change your password'
    fill_in 'user[password]', with: 'brand-new-pass-1'
    fill_in 'user[password_confirmation]', with: 'brand-new-pass-1'
    click_button 'Change my password'

    # Devise signs the user in after a successful reset
    assert_text 'Your password was changed successfully. You are now signed in.'
    click_link 'Sign out'
    assert_selector 'a', text: 'Sign in'

    # The new password works through the normal sign-in form
    visit_apex '/users/sign_in'
    within "form[action='/users/sign_in']" do
      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'brand-new-pass-1'
      click_button 'Sign in'
    end
    assert_selector 'a', text: 'Sign out'
  end
end
