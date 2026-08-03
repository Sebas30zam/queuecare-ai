module Dashboard
  class AiAssistantController < ApplicationController
    before_action :authenticate_user!
    before_action -> { require_role!("admin", "supervisor") }

    def create
      question = params[:question].to_s.strip

      if question.blank?
        return render json: {
          error: "Question is required."
        }, status: :unprocessable_entity
      end

      answer = Ai::OperationsAssistantService.new(
        date: Date.current,
        question:
      ).call

      render json: {
        answer:
      }
    rescue Ai::GeminiClient::Error => error
      Rails.logger.error(
        "AI operations assistant request failed: #{error.message}"
      )

      render json: {
        error: "The AI assistant is temporarily unavailable."
      }, status: :bad_gateway
    end
  end
end
