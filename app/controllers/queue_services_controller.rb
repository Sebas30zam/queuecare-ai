class QueueServicesController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }

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
end
