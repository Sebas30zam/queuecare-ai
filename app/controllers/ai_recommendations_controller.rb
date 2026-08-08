class AiRecommendationsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role!(:admin, :supervisor) }

  def index
    date = Date.current

    operational_recommendations =
      Analytics::OperationalRecommendationsService.new(
        date:
      ).call

    render inertia: "ai_recommendations/index",
           props: {
             date: date.iso8601,
             operational_recommendations:
               operational_recommendations.slice(
                 :status,
                 :recommendations,
                 :next_holiday_alert
               )
           }
  end
end
