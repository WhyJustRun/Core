require 'application_system_test_case'

class ClubAdminTest < ApplicationSystemTestCase
  test "editing the club settings persists" do
    sign_in_to_club users(:webmaster)
    visit_club '/clubs/edit'
    assert_selector 'h1', text: 'Edit Club Information'

    fill_in 'club[name]', with: 'Club A Orienteering Society'
    fill_in 'club[location]', with: 'Vancouver, BC'
    fill_in 'club[url]', with: 'https://cluba.example.com'
    select 'America/Whitehorse', from: 'club[timezone]'
    click_button 'Save'

    assert_text 'Updated club'
    assert_selector 'h1', text: 'Admin tools'
    # The new name shows up in the club layout header
    assert_selector 'header h1', text: 'Club A Orienteering Society'

    club = clubs(:cluba).reload
    assert_equal 'Club A Orienteering Society', club.name
    assert_equal 'Vancouver, BC', club.location
    assert_equal 'https://cluba.example.com', club.url
    assert_equal 'America/Whitehorse', club.timezone
  end

  test "granting and revoking a privilege" do
    sign_in_to_club users(:webmaster)
    visit_club '/privileges/'
    assert_selector 'h1', text: 'Privileges'

    # The webmaster can only manage groups at or below their own level
    assert_selector 'dt', text: 'Webmaster'
    assert_selector 'dt', text: 'Executive'
    assert_no_selector 'dt', text: 'Administrator'

    select 'Mary Member', from: 'privilege[user_id]'
    select 'Executive', from: 'privilege[group_id]'
    click_button 'Add'

    assert_text 'The privilege has been added.'
    row = find('tr', text: 'Mary Member')
    row.assert_text 'Executive'
    assert Privilege.exists?(user: users(:member), user_group: groups(:cluba_executive))

    find('tr', text: 'Mary Member').find('button').click
    assert_text 'The privilege has been deleted.'
    assert_no_selector 'tr', text: 'Mary Member'
    assert_not Privilege.exists?(user: users(:member), user_group: groups(:cluba_executive))
  end
end
