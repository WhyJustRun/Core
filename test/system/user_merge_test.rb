require 'application_system_test_case'

class UserMergeTest < ApplicationSystemTestCase
  test "the duplicates screen merges a fake account into the real one" do
    real = User.create!(name: 'Robin Runner', email: 'robin@example.com',
                        password: 'password123', password_confirmation: 'password123',
                        club: clubs(:cluba))
    fake = User.create_fake('Robin Runner')
    result = Result.create!(user: fake, course: courses(:race_long), status: :ok)

    sign_in_to_club users(:webmaster)
    visit_club '/users/showDuplicates'
    assert_selector 'h1', text: 'Merge user accounts'

    # The webmaster's merge level does not include the manual merge form
    assert_no_text 'Manual merge'

    # The real account is classified as primary, the fake one as duplicate
    row = find('tr', text: 'Robin Runner')
    row.assert_selector '.label', text: 'Real'
    row.assert_selector '.label', text: 'Fake'
    assert_equal real.id.to_s, row.all('td')[2].text
    assert_equal fake.id.to_s, row.all('td')[6].text

    within(row) { click_button 'Merge' }

    # The pair is gone and the fake account's data now points at the real one
    assert_selector 'h1', text: 'Merge user accounts'
    assert_no_selector 'tr', text: 'Robin Runner'
    assert_not User.exists?(fake.id)
    assert User.exists?(real.id)
    assert_equal real.id, result.reload.user_id
  end
end
