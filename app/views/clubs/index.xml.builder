xml.instruct!
xml.OrganisationList(
	:xmlns => "http://www.orienteering.org/datastandard/3.0",
	:'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
	:iofVersion => "3.0",
	:createTime => Time.zone.now.iso8601,
	:creator => "WhyJustRun"
	) do
	# TODO-RWP Event classification list
	# TODO-RWP How to do Event Races?
	@clubs.each { |club|
		xml.Organisation do
			xml.Id club.id
			xml.Name club.name
			xml.ShortName club.acronym
            unless club.parent_id.nil? then
                xml.ParentOrganisation(:idref => club.parent_id)
            end
			unless club.club_category.nil? then
				xml.Type club.club_category.name
			end
			#xml.comment! "Tree structure ParentOrganization is coming soon"
			xml.Parent_Id (club.parent_id)
			xml.Contact(club.url, :type => "WebAddress")
			xml.Position(:lat => club.lat, :lng => club.lng)
		end
	}
end
