builder.Person do
  builder.PersonName do
    builder.Given user.first_name
    builder.Family user.last_name
  end

  builder.PersonId user.id
end
