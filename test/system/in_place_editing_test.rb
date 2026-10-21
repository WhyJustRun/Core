require 'application_system_test_case'

class InPlaceEditingTest < ApplicationSystemTestCase
  test "editing a home page content block in place" do
    block = content_blocks(:cluba_general_information)
    sign_in_to_club users(:executive)

    find("#content-block-#{block.id}").click
    within "#content-block-#{block.id}" do
      find('textarea').set('<h2>Hello from the club</h2>')
      click_button 'Save'
    end

    assert_selector "#content-block-#{block.id} h2", text: 'Hello from the club'
    assert_equal '<h2>Hello from the club</h2>', block.reload.content

    # The saved content survives a reload
    visit_club '/'
    assert_selector "#content-block-#{block.id} h2", text: 'Hello from the club'
  end

  test "editing a resource page title and body in place" do
    page_record = pages(:cluba_trail_guide)
    sign_in_to_club users(:executive)
    visit_club "/pages/#{page_record.id}"

    find("#page-resource-title-#{page_record.id}").click
    within "#page-resource-title-#{page_record.id}" do
      find('input').set('Trail Guide 2026')
      click_button 'Save'
    end
    assert_selector 'h1', text: 'Trail Guide 2026'
    assert_equal 'Trail Guide 2026', page_record.reload.name

    find("#page-resource-#{page_record.id}").click
    within "#page-resource-#{page_record.id}" do
      find('textarea').set('<p>All the trails, now with directions.</p>')
      click_button 'Save'
    end
    assert_selector "#page-resource-#{page_record.id} p", text: 'All the trails, now with directions.'
    assert_equal '<p>All the trails, now with directions.</p>', page_record.reload.content

    visit_club "/pages/#{page_record.id}"
    assert_selector 'h1', text: 'Trail Guide 2026'
    assert_selector "#page-resource-#{page_record.id} p", text: 'All the trails, now with directions.'
  end

  test "members without the edit privilege get no in-place editors" do
    block = content_blocks(:cluba_general_information)
    sign_in_to_club users(:member)

    assert_selector "#content-block-#{block.id}"
    assert_no_selector "#content-block-#{block.id}.wjr-editable"
    find("#content-block-#{block.id}").click
    assert_no_selector "#content-block-#{block.id} textarea"
  end
end
