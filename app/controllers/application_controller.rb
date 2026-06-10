class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  inertia_share(
    auth: lambda {
      {
        user: current_user && {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          role: current_user.role.name
        }
      }
    },
    flash: lambda {
      {
        notice: flash[:notice],
        alert: flash[:alert]
      }.compact
    }
  )

  private

  def current_user
    @current_user ||= User.includes(:role).find_by(id: session[:user_id])
  end

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  def require_role!(*role_names)
    return if current_user&.role&.name.in?(role_names.map(&:to_s))

    redirect_to root_path, alert: "You are not authorized to access this page."
  end
end
