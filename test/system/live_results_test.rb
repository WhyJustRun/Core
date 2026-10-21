require 'application_system_test_case'

class LiveResultsTest < ApplicationSystemTestCase
  LIVE_RESULT_LIST_XML = <<~XML.freeze
    <?xml version="1.0" encoding="UTF-8"?>
    <ResultList xmlns="http://www.orienteering.org/datastandard/3.0" iofVersion="3.0" createTime="2025-06-15T18:30:00-07:00" status="Snapshot">
      <Event><Name>Spring Sprint</Name></Event>
      <ClassResult>
        <Class><Name>Long Course</Name></Class>
        <PersonResult>
          <Person><Name><Family>Member</Family><Given>Mary</Given></Name></Person>
          <Result><Time>3930</Time><Position>1</Position><Status>OK</Status></Result>
        </PersonResult>
      </ClassResult>
    </ResultList>
  XML

  test "an organizer can show and hide the live results" do
    event = events(:cluba_race)
    result_list = ResultList.create!(event: event, user: users(:organizer),
                                     status: ResultList::LIVE_STATUS, visible: false,
                                     data: LIVE_RESULT_LIST_XML, upload_time: Time.current)

    sign_in_to_club users(:organizer)
    visit_club "/events/view/#{event.id}"

    # Hidden live results show editors only the toggle button
    assert_selector 'h2', text: 'Live Results'
    assert_no_text 'these are not finalized'
    click_button 'Show Live Results'

    # Toggling persists and re-renders the event page with the list visible
    assert_button 'Hide Live Results'
    assert result_list.reload.visible

    # The list populates from the live IOF XML feed
    assert_text 'Live results - these are not finalized!'
    assert_selector '.result-list h3', text: 'Long Course'
    assert_selector '.result-list td', text: 'Mary Member'
    assert_selector '.result-list td', text: '01:05:30'
    # The creation time renders in the browser's local time
    assert_text(/Results produced on \w+, June 1[56]th 2025/)

    click_button 'Hide Live Results'
    assert_button 'Show Live Results'
    assert_not result_list.reload.visible
    assert_no_text 'these are not finalized'
  end

  test "members do not get the toggle and hidden live results stay hidden" do
    event = events(:cluba_race)
    ResultList.create!(event: event, user: users(:organizer),
                       status: ResultList::LIVE_STATUS, visible: false,
                       data: LIVE_RESULT_LIST_XML, upload_time: Time.current)

    sign_in_to_club users(:member)
    visit_club "/events/view/#{event.id}"

    assert_selector 'h1', text: 'Spring Sprint'
    assert_no_button 'Show Live Results'
    assert_no_text 'these are not finalized'
  end
end
