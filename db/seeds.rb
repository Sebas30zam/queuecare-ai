roles = [
  "admin",
  "receptionist",
  "agent",
  "supervisor"
]

roles.each do |role_name|
  Role.find_or_create_by!(name: role_name)
end

users = [
  {
    name: "Admin User",
    email: "admin@queuecare.com",
    role: "admin"
  },
  {
    name: "Receptionist User",
    email: "receptionist@queuecare.com",
    role: "receptionist"
  },
  {
    name: "Agent User",
    email: "agent@queuecare.com",
    role: "agent"
  },
  {
    name: "Supervisor User",
    email: "supervisor@queuecare.com",
    role: "supervisor"
  }
]

users.each do |user_data|
  role = Role.find_by!(name: user_data[:role])

  user = User.find_or_initialize_by(email: user_data[:email])
  user.name = user_data[:name]
  user.role = role
  user.active = true
  user.password = "password123"
  user.password_confirmation = "password123"
  user.save!
end
