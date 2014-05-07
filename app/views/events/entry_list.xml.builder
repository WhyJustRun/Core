xml.instruct!
xml.EntryList(
:xmlns => "http://www.orienteering.org/datastandard/3.0",
:'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
:iofVersion => "3.0",
:createTime => Time.zone.now.iso8601,
:creator => "WhyJustRun"
) do
  render partial: 'events/event_3', locals: { builder: xml, event: @event }

  @event.courses.each { |course|
    xml.comment! course.name + " entries"
    course.results.each { |result|
      user = result.user
      xml.PersonEntry do
        xml.Id result.id
        render partial: 'users/person_3', locals: { builder: xml, user: user }

        unless user.club.nil?
          xml.Organisation do
            render partial: 'clubs/organisation_inner', locals: { builder: xml, club: user.club }
          end
        end

        render partial: 'users/control_cards_3', locals: { builder: xml, user: user }
        xml.Class do
          xml.Id course.id
          xml.Name course.name
        end
        # TODO-RWP Add registration time to database <EntryTime>2011-07-14T18:20:05+01:00</EntryTime>
      end
    }
  }
end
