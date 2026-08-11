class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }

  def index
    start_date, end_date = dashboard_date_range

    metrics = Dashboard::OperationalMetricsService.new(
      start_date:,
      end_date:
    ).call

    operational_recommendations =
      Analytics::OperationalRecommendationsService.new(
        date: end_date
      ).call

    render inertia: "dashboard/index",
           props: build_dashboard_index_props(
             metrics,
             operational_recommendations
           )
  end

  private

  def dashboard_date_range
    return [ Date.current, Date.current ] if date_range_params_blank?

    start_date = parse_dashboard_date(params[:start_date])
    end_date = parse_dashboard_date(params[:end_date])

    return [ Date.current, Date.current ] if start_date.nil? || end_date.nil?
    return [ Date.current, Date.current ] if start_date > end_date

    [ start_date, end_date ]
  end

  def date_range_params_blank?
    params[:start_date].blank? && params[:end_date].blank?
  end

  def parse_dashboard_date(value)
    return if value.blank?

    Date.iso8601(value)
  rescue Date::Error
    nil
  end

  def build_dashboard_index_props(
    metrics,
    operational_recommendations
  )
    {
      start_date: metrics[:start_date],
      end_date: metrics[:end_date],
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
          :recommendations,
          :next_holiday_alert
        )
    }
  end
end
