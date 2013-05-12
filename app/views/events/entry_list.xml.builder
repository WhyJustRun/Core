xml.instruct!
xml.EntryList(
:xmlns => "http://www.orienteering.org/datastandard/3.0",
:'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
:iofVersion => "3.0",
:createTime => Time.zone.now.iso8601,
:creator => "WhyJustRun"
) do
  # TODO-RWP Event classification list
  # TODO-RWP How to do Event Races?
  xml.Event do
    xml.Id @event.id
    xml.Name @event.name
    xml.StartTime do
      xml.Date @event.local_date.strftime('%F')
      xml.Time @event.local_date.strftime('%T') + @event.local_date.formatted_offset
    end
    
    @event.courses.each { |course|
      xml.Class(:idref => course.id)
    }
  end
	
  @event.courses.each { |course|
    xml.comment! course.name + " entries"
    course.results.each { |result|
      user = result.user
      xml.PersonEntry do
        xml.Id result.id
        xml.Person do
          xml.Id user.id
          xml.Name do
            xml.Given user.first_name
            xml.Family user.last_name
          end
        end
	
        club = user.club        
        unless club.nil?
          xml.Organization do
            xml.Id club.id
            xml.Name club.name
          end
        end
				
        xml.ControlCard user.si_number unless user.si_number.nil?
        xml.Class do
          xml.Id course.id
          xml.Name course.name
        end
        # TODO-RWP Add registration time to database <EntryTime>2011-07-14T18:20:05+01:00</EntryTime>
      end
    }
  }
end
