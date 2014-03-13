xml.instruct!
xml.declare! :DOCTYPE, :StartList, :SYSTEM, "IOFdata.dtd"
xml.Wrapper do
  xml << render(partial: "events/list_2", locals: { events: [@event] })
  xml.StartList do
    # TODO-RWP Event classification list
    # TODO-RWP How to do Event Races?
    xml.IOFVersion version: "2.0.3"
    xml.EventId({ type: "int", idManager: "WhyJustRun" }, @event.id)
    @event.courses.each { |course|
      xml.ClassStart do
        xml.ClassShortName course.name
        course.results.each { |participant|
          user = participant.user
          xml.PersonStart do
            render partial: 'users/person_2', locals: { builder: xml, user: user }
            render partial: 'clubs/club_2', locals: { builder: xml, club: user.club } unless user.club.nil?

            xml.RaceStart do
              xml.Start do
                xml.CCardId user.si_number unless user.si_number.nil?
                xml.CourseLength course.distance
              end

              # TODO-RWP Change when actual event race support is added.
              xml.EventRaceId @event.id
            end
          end
        }
      end
    }
  end
end
