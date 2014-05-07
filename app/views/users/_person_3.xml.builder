gender = { gender: user.gender } unless user.gender.nil?
builder.Person(gender) do
  builder.Id user.id
  builder.Name do
    builder.Given user.first_name
    builder.Family user.last_name
  end

  builder.Contact({ type: 'WebAddress' }, user_url(user.id))

  # TODO: Nationality
end
