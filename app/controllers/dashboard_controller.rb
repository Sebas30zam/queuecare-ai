class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }

  def index
    metrics = Dashboard::OperationalMetricsService.new(
      date: Date.current
    ).call

    render inertia: "dashboard/index",
           props: build_dashboard_index_props(metrics)
  end

  private

  def build_dashboard_index_props(metrics)
    {
      date: metrics[:date],
      summary: metrics[:summary],
      services: metrics[:services],
      hourly_activity: metrics[:hourly_activity],
      status_distribution: metrics[:status_distribution],
      service_windows: metrics[:service_windows],
      critical_services: metrics[:critical_services],
      insights: metrics[:insights]
    }
  end
end
