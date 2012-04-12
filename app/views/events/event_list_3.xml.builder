xml.instruct!
xml.EventList(
:xmlns       => "http://www.orienteering.org/datastandard/3.0",
:'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
:iofVersion  => "3.0",
:createTime  => Time.zone.now.iso8601,
:creator     => "WhyJustRun"
) do
  # TODO-RWP Event classification list
  # TODO-RWP How to do Event Races?
  @events.each { |event|
    xml.Event do
      xml.Id event.id
      xml.Name event.name
      xml.StartTime do
        xml.Date event.local_date.strftime('%F')
        xml.Time event.local_date.strftime('%T') + event.local_date.formatted_offset
      end
	    
      event.courses.each { |course|
        xml.Class do
          xml.Id course.id
          xml.Name course.name
        end
      }
    end
  }
end
