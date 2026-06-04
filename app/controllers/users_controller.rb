class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }

  def index
    users = User.includes(:role).order(:name).map do |user|
      {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role.name,
        active: user.active
      }
    end

    render inertia: "users/index", props: {
      users: users
    }
  end
end
