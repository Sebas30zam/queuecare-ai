require "json"

module Ai
  class OperationsPromptBuilder
    MAX_QUESTION_LENGTH = 1_000

    INSTRUCTIONS = <<~TEXT.freeze
      Eres el asistente de operaciones de QueueCare AI.
      Responde únicamente con base en los datos proporcionados.
      No inventes métricas, eventos, causas ni recomendaciones.
      Si los datos no permiten responder, indícalo claramente.
      Responde en el mismo idioma de la pregunta del usuario, de manera clara y práctica.
    TEXT

    def initialize(question:, context:)
      @question = question.to_s.strip
      @context = context
    end

    def call
      validate_question!

      {
        instructions: INSTRUCTIONS,
        input: build_input
      }
    end

    private

    attr_reader :question, :context

    def validate_question!
      if question.empty?
        raise ArgumentError, "Question cannot be blank"
      end

      return unless question.length > MAX_QUESTION_LENGTH

      raise ArgumentError,
            "Question cannot exceed 1000 characters"
    end

    def build_input
      <<~TEXT
        Fecha de la operación:
        #{context[:date]}

        Contexto operativo disponible:
        #{JSON.pretty_generate(context)}

        Pregunta del usuario:
        #{question}
      TEXT
    end
  end
end
