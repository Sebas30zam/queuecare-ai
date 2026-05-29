class SessionsController < ApplicationController
  def new
    redirect_to root_path and return if current_user

    render inertia: "auth/login"
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.active? && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path
    else
      redirect_to login_path, inertia: {
        errors: {
          email: "Invalid email or password"
        }
      }
    end
  end

  def destroy
    reset_session
    redirect_to login_path
  end
end
