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
        xml.ISODate event.date.strftime('%FT%T.000Z')
      end
      
      xml.EndTime do
        xml.Date event.local_finish_date.strftime('%F')
        xml.Time event.local_finish_date.strftime('%T') + event.local_finish_date.formatted_offset
        xml.ISODate event.finish_date.strftime('%FT%T.000Z')
      end
	  
	  classification = event.event_classification
	  if (not classification.nil?) then
	    xml.Classification classification.iof_3_0_name
	  end
	  
	  club = event.club
	  xml.Organiser do
    	  xml.Id club.id
    	  xml.Name club.name
    	  if (not club.parent_id.nil?) then
    	    xml.ParentOrganisationId club.parent_id
    	  end
    	  xml.ShortName club.acronym
	  end
	  
	  if (not event.url.nil?) then
	    xml.URL({:type => 'Website'}, event.url)
	  end
	  series = event.series
	  if (not series.nil?) then
	    xml.Extensions do
          xml.Series do
            xml.Id series.id
            xml.Name series.name
            xml.Acronym series.acronym
            xml.Color series.color
          end
        end
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
