class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }

  def index
    date = Date.current

    metrics = Dashboard::OperationalMetricsService.new(
      date:
    ).call

    operational_recommendations =
      Analytics::OperationalRecommendationsService.new(
        date:
      ).call

    render inertia: "dashboard/index",
           props: build_dashboard_index_props(
             metrics,
             operational_recommendations
           )
  end

  private

  def build_dashboard_index_props(
    metrics,
    operational_recommendations
  )
    {
      date: metrics[:date],
      summary: metrics[:summary],
      services: metrics[:services],
      hourly_activity: metrics[:hourly_activity],
      status_distribution: metrics[:status_distribution],
      service_windows: metrics[:service_windows],
      critical_services: metrics[:critical_services],
      insights: metrics[:insights],
      operational_recommendations:
        operational_recommendations.slice(
          :status,
          :recommendations
        )
    }
  end
end
