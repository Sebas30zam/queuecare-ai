class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    case current_user.role.name
    when "admin", "supervisor"
      redirect_to dashboard_path
    when "receptionist"
      redirect_to tickets_reception_path
    when "agent"
      redirect_to agent_queue_path
    else
      redirect_to login_path
    end
  end
end
