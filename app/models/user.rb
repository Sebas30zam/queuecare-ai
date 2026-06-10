class User < ApplicationRecord
  belongs_to :role

  has_many :created_tickets,
           class_name: "Ticket",
           foreign_key: :created_by_id,
           dependent: :restrict_with_exception

  has_many :assigned_tickets,
           class_name: "Ticket",
           foreign_key: :assigned_agent_id,
           dependent: :nullify

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
end
