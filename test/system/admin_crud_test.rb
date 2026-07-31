require 'application_system_test_case'

class AdminCrudTest < ApplicationSystemTestCase
  test "adding, editing and deleting a membership" do
    sign_in_to_club users(:executive)
    visit_club '/memberships/'
    assert_selector 'h1', text: 'Memberships'

    select 'Oscar Organizer', from: 'membership[user_id]'
    fill_in 'membership[year]', with: '2026'
    click_button 'Add membership'

    assert_text 'The membership has been updated.'
    membership = Membership.find_by(user: users(:organizer), club: clubs(:cluba), year: 2026)
    assert_not_nil membership
    assert_selector 'tr', text: 'Oscar Organizer'

    within find('tr', text: 'Oscar Organizer') do
      click_link 'Edit'
    end
    assert_selector 'h1', text: 'Membership'
    fill_in 'membership[year]', with: '2025'
    click_button 'Update'

    assert_text 'The membership has been updated.'
    assert_equal 2025, membership.reload.year

    within find('tr', text: 'Oscar Organizer') do
      click_button 'Remove'
    end
    assert_text 'The membership has been deleted.'
    assert_no_selector 'tr', text: 'Oscar Organizer'
    assert_not Membership.exists?(membership.id)
  end

  test "adding and deleting an official through the person picker" do
    sign_in_to_club users(:webmaster)
    visit_club '/officials/'
    assert_selector 'h1', text: 'List of officials'

    fill_in 'UserName', with: 'Wendy'
    find('ul.typeahead li a', text: 'Wendy Webmaster').click
    within "form[action='/officials/add']" do
      select 'Level 2', from: 'official[official_classification_id]'
      fill_in 'official[date]', with: '2026-05-01'
      find('button[type="submit"]').click
    end

    assert_text 'The official has been added.'
    official = Official.find_by(user: users(:webmaster),
                                official_classification: official_classifications(:level_two))
    assert_not_nil official
    assert_equal Date.new(2026, 5, 1), official.date.to_date
    assert_selector 'tr', text: 'Wendy Webmaster'

    within find('tr', text: 'Wendy Webmaster') do
      find('button.btn-danger').click
    end
    assert_text 'The official was deleted.'
    assert_no_selector 'tr', text: 'Wendy Webmaster'
    assert_not Official.exists?(official.id)
  end

  test "editing a map standard" do
    map_standard = MapStandard.create!(name: 'ISOM', color: 'rgba(0,0,0,1)')

    sign_in_to_club users(:admin)
    visit_club '/mapStandards/'
    assert_selector 'h1', text: 'Map Standards'

    within find('tr', text: 'ISOM') do
      find("a[href='/mapStandards/edit/#{map_standard.id}']").click
    end
    assert_selector 'h1', text: 'Map standard'

    fill_in 'map_standard[name]', with: 'ISOM 2017'
    fill_in 'map_standard[color]', with: 'rgba(10,20,30,1)'
    fill_in 'map_standard[description]', with: 'Forest mapping standard'
    click_button 'Save'

    assert_text 'The map standard has been updated.'
    assert_selector 'tr', text: 'ISOM 2017'
    map_standard.reload
    assert_equal 'ISOM 2017', map_standard.name
    assert_equal 'rgba(10,20,30,1)', map_standard.color
    assert_equal 'Forest mapping standard', map_standard.description
  end

  test "editing a role" do
    role = roles(:course_planner)

    sign_in_to_club users(:admin)
    visit_club '/roles/'
    assert_selector 'h1', text: 'Roles'

    within find('tr', text: 'Course Planner') do
      find("a[href='/roles/edit/#{role.id}']").click
    end
    assert_selector 'h1', text: 'Role'

    fill_in 'role[name]', with: 'Course Setter'
    fill_in 'role[description]', with: 'Sets the courses'
    click_button 'Save'

    assert_text 'The role has been updated.'
    assert_selector 'tr', text: 'Course Setter'
    role.reload
    assert_equal 'Course Setter', role.name
    assert_equal 'Sets the courses', role.description
  end
end
