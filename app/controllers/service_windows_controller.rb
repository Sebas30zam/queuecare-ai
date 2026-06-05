class ServiceWindowsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }

  def index
    service_windows = ServiceWindow.includes(:queue_service).order(:code).map do |service_window|
      {
        id: service_window.id,
        name: service_window.name,
        code: service_window.code,
        active: service_window.active,
        queue_service: {
          id: service_window.queue_service.id,
          name: service_window.queue_service.name,
          code: service_window.queue_service.code
        }
      }
    end

    render inertia: "service-windows/index", props: {
      service_windows: service_windows
    }
  end
end
