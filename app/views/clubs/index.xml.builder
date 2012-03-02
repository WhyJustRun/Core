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
			unless club.club_category.nil? then
				xml.Type club.club_category.name
			end
			#unless club.parent_id.nil? then
			# xml.ParentOrganization club.parent_id
			#end
			xml.comment! "Tree structure ParentOrganization is coming soon"
			xml.Contact(club.url, :type => "WebAddress")
			xml.Position(:lat => club.lat, :lng => club.lng)
		end
	}
end
