builder.Club do
  builder.ClubId({ type: "int", idManager: "WhyJustRun" }, club.id)
  builder.ShortName club.acronym
  builder.WebURL club.url
end
