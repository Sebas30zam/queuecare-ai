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

queue_services = [
  {
    name: "Admissions",
    code: "ADM",
    description: "Student admissions and enrollment support.",
    estimated_attention_minutes: 12
  },
  {
    name: "Finance",
    code: "FIN",
    description: "Financial procedures, payments, and account inquiries.",
    estimated_attention_minutes: 15
  },
  {
    name: "Registration",
    code: "REG",
    description: "Course registration and academic record procedures.",
    estimated_attention_minutes: 10
  },
  {
    name: "Academic Support",
    code: "ACS",
    description: "Academic assistance and student support services.",
    estimated_attention_minutes: 18
  },
  {
    name: "Cashier",
    code: "CAS",
    description: "Cashier payments and receipt processing.",
    estimated_attention_minutes: 8
  },
  {
    name: "Service Platform",
    code: "SRV",
    description: "General service desk and institutional support.",
    estimated_attention_minutes: 12
  }
]

queue_services.each do |service_data|
  service = QueueService.find_or_initialize_by(code: service_data[:code])
  service.name = service_data[:name]
  service.description = service_data[:description]
  service.active = true
  service.estimated_attention_minutes = service_data[:estimated_attention_minutes]
  service.save!
end

service_windows = [
  {
    name: "Window 1",
    code: "W1",
    queue_service_code: "ADM"
  },
  {
    name: "Window 2",
    code: "W2",
    queue_service_code: "FIN"
  },
  {
    name: "Window 3",
    code: "W3",
    queue_service_code: "REG"
  },
  {
    name: "Window 4",
    code: "W4",
    queue_service_code: "ACS"
  },
  {
    name: "Window 5",
    code: "W5",
    queue_service_code: "CAS"
  },
  {
    name: "Window 6",
    code: "W6",
    queue_service_code: "SRV"
  }
]

service_windows.each do |window_data|
  queue_service = QueueService.find_by!(code: window_data[:queue_service_code])

  service_window = ServiceWindow.find_or_initialize_by(code: window_data[:code])
  service_window.name = window_data[:name]
  service_window.queue_service = queue_service
  service_window.active = true
  service_window.save!
end
