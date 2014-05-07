unless user.si_number.nil?
  builder.ControlCard({ punchingSystem: "SI" }, user.si_number)
end
