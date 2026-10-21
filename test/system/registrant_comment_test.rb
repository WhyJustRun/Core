require 'application_system_test_case'

class RegistrantCommentTest < ApplicationSystemTestCase
  test "a registrant can add a comment through the modal" do
    event = events(:cluba_race)
    event.update!(date: 2.weeks.from_now, finish_date: nil)
    result = results(:member_long)

    sign_in_to_club users(:member)
    visit_club "/events/view/#{event.id}"

    within find('tr', text: 'Mary Member') do
      click_button 'Add Comment'
    end
    within "#change-comment-modal-#{result.id}" do
      find('textarea').set('Can offer a ride from downtown')
      click_button 'Save'
    end

    # Saving posts the comment and returns to the event page. The event page
    # is already visible under the modal, so wait on the database effect
    # rather than on a page element.
    wait_for_condition(message: 'comment was not saved') do
      result.reload.registrant_comment == 'Can offer a ride from downtown'
    end

    # The entry now offers editing and shows the comment bubble
    within find('tr', text: 'Mary Member') do
      assert_button 'Edit Comment'
      assert_selector 'button .glyphicon-comment'
    end
  end

  test "a registrant can change an existing comment" do
    event = events(:cluba_race)
    event.update!(date: 2.weeks.from_now, finish_date: nil)
    result = results(:member_long)
    result.update!(registrant_comment: 'Old comment')

    sign_in_to_club users(:member)
    visit_club "/events/view/#{event.id}"

    within find('tr', text: 'Mary Member') do
      click_button 'Edit Comment'
    end
    within "#change-comment-modal-#{result.id}" do
      assert_selector 'h4', text: 'Change Comment'
      assert_equal 'Old comment', find('textarea').value
      find('textarea').set('Ride offer withdrawn')
      click_button 'Save'
    end

    wait_for_condition(message: 'comment was not saved') do
      result.reload.registrant_comment == 'Ride offer withdrawn'
    end
  end
end
