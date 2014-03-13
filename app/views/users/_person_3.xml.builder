builder.Person do
  builder.Id user.id
  builder.Name do
    builder.Given user.first_name
    builder.Family user.last_name
  end

  builder.Contact({ type: 'WebAddress' }, user_url(user.id))
end
