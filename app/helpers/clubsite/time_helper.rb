module Clubsite
  # Event/result time formatting. Times render in the request's time zone,
  # which BaseController sets to the club's zone.
  module TimeHelper
    # Date range for the event page header, collapsing the finish onto the
    # start when both fall on the same day. A NULL finish date renders the
    # start only.
    def formatted_event_date(event)
      start_time = event.date
      finish_time = event.read_attribute(:finish_date)
      if finish_time.nil?
        long_date_with_time(start_time)
      elsif same_calendar_day?(start_time, finish_time)
        "#{long_date_with_time(start_time)} - #{time_of_day(finish_time)}"
      else
        "#{long_date_with_time(start_time)} - #{long_date_with_time(finish_time)}"
      end
    end

    # Compact date range for event boxes, e.g. "Sun June 15th 10:00am"
    def event_box_date(event)
      start_time = event.date
      finish_time = event.read_attribute(:finish_date)
      if finish_time.nil?
        day_date_with_time(start_time)
      elsif same_calendar_day?(start_time, finish_time)
        "#{day_date_with_time(start_time)} - #{time_of_day(finish_time)}"
      else
        "#{day_date(start_time)} - #{day_date(finish_time)}"
      end
    end

    # e.g. "Jun 15th 10:00am", used for registration deadlines
    def short_date_with_time(time)
      "#{time.strftime('%b')} #{time.day.ordinalize} #{time_of_day(time)}"
    end

    # H:MM:SS with unpadded hours, e.g. "1:02:03"
    def formatted_result_time(seconds)
      return nil if seconds.nil?

      seconds = seconds.to_i
      format('%d:%02d:%02d', seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    end

    # A <time> element that the clubsite JS replaces with a relative time
    def timeago(time)
      iso = time.iso8601
      content_tag(:time, iso, class: 'timeago', datetime: iso)
    end

    private

    def same_calendar_day?(first, second)
      first.to_date == second.to_date
    end

    # e.g. "10:00am"
    def time_of_day(time)
      time.strftime('%-l:%M%P')
    end

    # e.g. "June 15th 2025 10:00am"
    def long_date_with_time(time)
      "#{time.strftime('%B')} #{time.day.ordinalize} #{time.year} #{time_of_day(time)}"
    end

    # e.g. "Sun June 15th"
    def day_date(time)
      "#{time.strftime('%a %B')} #{time.day.ordinalize}"
    end

    def day_date_with_time(time)
      "#{day_date(time)} #{time_of_day(time)}"
    end
  end
end
