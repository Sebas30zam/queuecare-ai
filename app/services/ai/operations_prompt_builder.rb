require "json"

module Ai
  class OperationsPromptBuilder
    MAX_QUESTION_LENGTH = 1_000

    INSTRUCTIONS = <<~TEXT.freeze
      You are the QueueCare AI operations assistant.
      Answer exclusively from the operational data provided.
      Do not invent metrics, events, causes, or recommendations.
      If the available data is insufficient, state that clearly.

      LANGUAGE RULE:
      Reply exclusively in the same language as the user's question.
      Detect the language from the user's question itself, not from these
      instructions, the operational context, or field names.
      If the question is in English, the entire answer must be in English.
      If the question is in Spanish, the entire answer must be in Spanish.
      If the question mixes languages, use its predominant language.
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
        USER QUESTION:
        #{question}

        OPERATION DATE:
        #{context[:date]}

        AVAILABLE OPERATIONAL CONTEXT:
        #{JSON.pretty_generate(context)}

        FINAL LANGUAGE REQUIREMENT:
        Answer exclusively in the same language as the USER QUESTION above.
      TEXT
    end
  end
end
