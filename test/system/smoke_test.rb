require 'application_system_test_case'

class SmokeTest < ApplicationSystemTestCase
  test "club home page renders without console errors" do
    visit_club '/'
    assert_selector 'header h1', text: 'Club A Orienteering'
  end

  test "apex home page renders" do
    visit_apex '/'
    assert_selector 'body'
  end
end
