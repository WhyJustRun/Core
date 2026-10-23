require 'application_system_test_case'

class AdminDashboardSystemTest < ApplicationSystemTestCase
  test 'a global administrator searches, reviews and deletes an account' do
    member = users(:member)
    result = results(:member_long)
    sign_in_through_browser users(:global_admin)
    click_link 'Admin', exact: true
    assert_selector 'h1', text: 'Admin'
    fill_in 'q', with: member.email
    click_button 'Search'
    within('tr', text: member.email) { click_link 'Review' }
    assert_selector 'h1', text: member.name

    fill_in 'confirm', with: 'wrong'
    click_button 'Delete account'
    assert_text "Type the user's ID"
    assert User.exists?(member.id)

    fill_in 'confirm', with: member.id
    click_button 'Delete account'
    assert_text "Deleted user ##{member.id}"
    assert_not User.exists?(member.id)
    assert_equal User.deleted_placeholder.id, result.reload.user_id
  end
end
