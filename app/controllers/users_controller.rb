class UsersController < ApplicationController
  ALLOWED_ROLES = %w[admin supervisor receptionist agent].freeze

  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }
  before_action :set_user, only: [ :edit, :update, :destroy ]
  before_action :prevent_supervisor_access_to_admin!,
                only: [ :edit, :update, :destroy ]

  def index
    users_scope = User.includes(:role).order(:name)

    if supervisor?
      users_scope =
        users_scope
          .joins(:role)
          .where.not(roles: { name: "admin" })
    end

    users = users_scope.map do |user|
      {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role.name,
        active: user.active,
        can_delete: user != current_user
      }
    end

    render inertia: "users/index", props: {
      users: users,
      current_user_id: current_user.id
    }
  end

  def new
    render inertia: "users/new", props: {
      roles: available_roles
    }
  end

  def create
    user = User.new(user_params.except(:role_id))
    user.role = available_roles_scope.find_by(id: user_params[:role_id])
    user.email = user.email.to_s.strip.downcase

    if user.save
      redirect_to users_path, notice: "User created successfully."
    else
      render inertia: "users/new",
             props: {
               roles: available_roles,
               errors: normalized_errors(user)
             },
             status: :unprocessable_entity
    end
  end

  def edit
    render inertia: "users/edit", props: {
      user: serialized_user_for_form(@user),
      roles: available_roles
    }
  end

  def update
    attributes = user_params.except(:role_id)

    if attributes[:password].blank?
      attributes = attributes.except(
        :password,
        :password_confirmation
      )
    end

    @user.assign_attributes(attributes)
    @user.role = available_roles_scope.find_by(id: user_params[:role_id])
    @user.email = @user.email.to_s.strip.downcase

    if @user.save
      redirect_to users_path, notice: "User updated successfully."
    else
      render inertia: "users/edit",
             props: {
               user: serialized_user_for_form(@user),
               roles: available_roles,
               errors: normalized_errors(@user)
             },
             status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path,
                  alert: "You cannot delete your own account."
      return
    end

    @user.destroy!

    redirect_to users_path, notice: "User deleted successfully."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to users_path,
                alert: "This user cannot be deleted because it has related records."
  end

  private

  def set_user
    @user = User.includes(:role).find(params[:id])
  end

  def prevent_supervisor_access_to_admin!
    return unless supervisor?
    return unless @user.role.name == "admin"

    redirect_to users_path,
                alert: "You are not authorized to manage this user."
  end

  def supervisor?
    current_user.role.name == "supervisor"
  end

  def available_roles_scope
    scope = Role.where(name: ALLOWED_ROLES)

    scope = scope.where.not(name: "admin") if supervisor?

    scope
  end

  def available_roles
    available_roles_scope.order(:name).map do |role|
      {
        id: role.id,
        name: role.name
      }
    end
  end

  def serialized_user_for_form(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role_id: user.role_id,
      role: user.role.name,
      active: user.active
    }
  end

  def normalized_errors(user)
    errors = user.errors.to_hash

    if errors[:role]
      errors[:role_id] = errors.delete(:role)
    end

    errors
  end

  def user_params
    params.expect(
      user: [
        :name,
        :email,
        :password,
        :password_confirmation,
        :role_id,
        :active
      ]
    )
  end
end
