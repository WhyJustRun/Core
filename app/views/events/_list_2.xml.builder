# IOF 2.0.3 Event list
xml.EventList do
  events.each { |event|
    xml.Event do
      xml.EventId({ type: "int", idManager: "WhyJustRun" }, event.id)
      xml.Name event.name
      xml.StartDate do
        xml.Date event.local_date.strftime('%F')
        xml.Clock event.local_date.strftime('%T')
      end
      xml.FinishDate do
        xml.Date event.local_finish_date.strftime('%F')
        xml.Clock event.local_finish_date.strftime('%T')
      end
      event.organizers.each { |organizer|
        xml.EventOfficial do
          xml.Person do
            xml.PersonName organizer.user.name
            xml.PersonId organizer.user.id
          end
        end
      }

      xml.Organizer do
        xml.Club do
          xml.ClubId({ type: "int", idManager: "WhyJustRun" }, event.club.id)
          xml.ShortName event.club.acronym
          xml.WebURL event.club.url
        end
      end

      xml.WebURL event.url
      xml.SpecialInfo do
        xml.SI_Title "Information"
        xml.SI_Content event.description
      end
    end
  }
end
