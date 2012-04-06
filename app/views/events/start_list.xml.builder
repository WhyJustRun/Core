xml.instruct!
xml.declare! :DOCTYPE, :StartList, :SYSTEM, "IOFdata.dtd"
xml.StartList do
  # TODO-RWP Event classification list
  # TODO-RWP How to do Event Races?
  xml.IOFVersion { :version => "2.0.3" }
  xml.EventId { :type => "int", :idManager => "OrienteerApp" }, @event.id
  @event.courses.each { |course|
    xml.ClassStart do
      xml.comment! 'Courses on the website map to Classes in IOF XML.'
      xml.ClassShortName course.name
      course.results.each { |participant|
        xml.PersonStart do
          xml.Person do
            xml.PersonName do
              xml.Given participant.user.first_name
              xml.Family participant.user.last_name
            end
						
            xml.PersonId participant.user.id
          end
					
          unless participant.user.club.nil?
            xml.Club do
              xml.ClubId participant.user.club.id
              xml.ShortName participant.user.club.acronym
              xml.Name participant.user.club.name
            end
          end
					
          xml.RaceStart do
            xml.Start do
              unless participant.user.si_number.nil?
                xml.CCardId participant.user.si_number
              end
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
