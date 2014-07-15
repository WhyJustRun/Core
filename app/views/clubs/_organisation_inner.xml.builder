builder.Id({ type: 'WhyJustRun' }, club.id)
builder.Name club.name
builder.ShortName club.acronym
builder.ParentOrganisationId club.parent_id unless club.parent_id.nil?
builder.Type club.club_category.name unless club.club_category.nil?
builder.Contact(club.url, type: "WebAddress")
builder.Position(lat: club.lat, lng: club.lng)
