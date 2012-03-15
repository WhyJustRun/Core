xml.instruct!
xml.declare! :DOCTYPE, :EventList, :SYSTEM, "IOFdata.dtd"
xml.EventList do
  # TODO-RWP Event classification list
  # TODO-RWP How to do Event Races?
  xml.Event do
    xml.EventId @event.id
    xml.Name @event.name
    # TODO-RWP xml.EventClassificationId
    xml.StartDate do
      xml.Date @event.local_date.strftime('%Y-%m-%d')
      xml.Clock @event.local_date.strftime('%H:%M:%S')
    end
    # TODO-RWP Finish date in database
    xml.FinishDate do
      xml.Date @event.local_date.strftime('%Y-%m-%d')
      xml.Clock @event.local_date.strftime('%H:%M:%S')
    end
    @event.organizers.each { |organizer|
      xml.EventOfficial do
        xml.Person do
          xml.PersonName organizer.user.name
          xml.PersonId organizer.user.id
        end
      end
    }
    xml.Organizer do
      xml.Club do
        xml.ShortName @event.club.acronym
      end
    end
    xml.WebURL @event.url
    xml.SpecialInfo do
      xml.SI_Title 'Information'
      		
      xml.SI_Content @event.rendered_description
    end
  end
end
