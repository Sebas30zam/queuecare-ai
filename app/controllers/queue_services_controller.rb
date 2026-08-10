class QueueServicesController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }
  before_action :set_queue_service, only: [ :edit, :update, :destroy ]

  def index
    queue_services = QueueService.order(:name).map do |queue_service|
      {
        id: queue_service.id,
        name: queue_service.name,
        code: queue_service.code,
        description: queue_service.description,
        active: queue_service.active,
        estimated_attention_minutes: queue_service.estimated_attention_minutes
      }
    end

    render inertia: "queue-services/index", props: {
      queue_services: queue_services
    }
  end

  def new
    render inertia: "queue-services/new"
  end

  def create
    queue_service = QueueService.new(queue_service_params)

    if queue_service.save
      redirect_to queue_services_path,
                  notice: "Queue service created successfully."
    else
      render inertia: "queue-services/new",
             props: {
               errors: queue_service.errors.to_hash
             },
             status: :unprocessable_entity
    end
  end

  def edit
    render inertia: "queue-services/edit", props: {
      queue_service: serialize_queue_service(@queue_service)
    }
  end

  def update
    if @queue_service.update(queue_service_params)
      redirect_to queue_services_path,
                  notice: "Queue service updated successfully."
    else
      render inertia: "queue-services/edit",
             props: {
               queue_service: serialize_queue_service(@queue_service),
               errors: @queue_service.errors.to_hash
             },
             status: :unprocessable_entity
    end
  end

  def destroy
    @queue_service.destroy!

    redirect_to queue_services_path,
                notice: "Queue service deleted successfully."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to queue_services_path,
                alert: "This service cannot be deleted because it has related operational records."
  end

  private

  def set_queue_service
    @queue_service = QueueService.find(params[:id])
  end

  def serialize_queue_service(queue_service)
    {
      id: queue_service.id,
      name: queue_service.name,
      code: queue_service.code,
      active: queue_service.active,
      estimated_attention_minutes: queue_service.estimated_attention_minutes
    }
  end

  def queue_service_params
    params.expect(
      queue_service: [
        :name,
        :code,
        :estimated_attention_minutes,
        :active
      ]
    )
  end
end
