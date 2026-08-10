class ServiceWindowsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }
  before_action :set_service_window, only: [ :edit, :update, :destroy ]

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

  def new
    render inertia: "service-windows/new", props: {
      queue_services: available_queue_services
    }
  end

  def create
    service_window = ServiceWindow.new(service_window_params)

    if service_window.save
      redirect_to service_windows_path,
                  notice: "Service window created successfully."
    else
      render inertia: "service-windows/new",
             props: {
               queue_services: available_queue_services,
               errors: normalized_errors(service_window)
             },
             status: :unprocessable_entity
    end
  end

  def edit
    render inertia: "service-windows/edit", props: {
      service_window: serialize_service_window(@service_window),
      queue_services: available_queue_services
    }
  end

  def update
    if @service_window.update(service_window_params)
      redirect_to service_windows_path,
                  notice: "Service window updated successfully."
    else
      render inertia: "service-windows/edit",
             props: {
               service_window: serialize_service_window(@service_window),
               queue_services: available_queue_services,
               errors: normalized_errors(@service_window)
             },
             status: :unprocessable_entity
    end
  end

  def destroy
    @service_window.destroy!

    redirect_to service_windows_path,
                notice: "Service window deleted successfully."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to service_windows_path,
                alert: "This service window cannot be deleted because it has related operational records."
  end

  private

  def set_service_window
    @service_window =
      ServiceWindow.includes(:queue_service).find(params[:id])
  end

  def available_queue_services
    QueueService.order(:name).map do |queue_service|
      {
        id: queue_service.id,
        name: queue_service.name,
        code: queue_service.code,
        active: queue_service.active
      }
    end
  end

  def serialize_service_window(service_window)
    queue_service = service_window.queue_service

    {
      id: service_window.id,
      name: service_window.name,
      code: service_window.code,
      active: service_window.active,
      queue_service_id: service_window.queue_service_id,
      queue_service: queue_service && {
        id: queue_service.id,
        name: queue_service.name,
        code: queue_service.code
      }
    }
  end

  def normalized_errors(service_window)
    errors = service_window.errors.to_hash

    if errors[:queue_service]
      errors[:queue_service_id] = errors.delete(:queue_service)
    end

    errors
  end

  def service_window_params
    params.expect(
      service_window: [
        :name,
        :code,
        :queue_service_id,
        :active
      ]
    )
  end
end
