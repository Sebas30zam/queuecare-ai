class User < ApplicationRecord
  belongs_to :role

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true
end
