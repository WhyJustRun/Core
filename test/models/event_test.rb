require 'test_helper'

class EventTest < ActiveSupport::TestCase
  test "local_date converts to the club's timezone" do
    event = events(:cluba_race)
    assert_equal 'America/Vancouver', event.local_date.time_zone.name
    assert_equal 10, event.local_date.hour # 17:00 UTC is 10:00 in Vancouver (PDT)
  end

  test "finish_date defaults to one hour after the start when unset" do
    event = events(:cluba_training)
    assert_equal event.date + 1.hour, event.finish_date
  end

  test "to_ics uses UTC times and does not change the current time zone" do
    event = events(:cluba_race)
    Time.use_zone('America/Vancouver') do
      ics = event.to_ics
      assert_equal 'America/Vancouver', Time.zone.name
      assert_equal event.date.utc, ics.dtstart
      assert_equal event.finish_date.utc, ics.dtend
    end
  end

  test "to_fullcalendar emits epoch timestamps and does not change the current time zone" do
    event = events(:cluba_race)
    Time.use_zone('America/Vancouver') do
      out = event.to_fullcalendar(false, nil)
      assert_equal 'America/Vancouver', Time.zone.name
      assert_equal event.date.to_i, out[:start]
      assert_equal event.finish_date.to_i, out[:end]
    end
  end

  test "has_organizer? detects event organizers" do
    assert events(:cluba_race).has_organizer?(users(:organizer))
    assert_not events(:cluba_race).has_organizer?(users(:member))
  end
end
