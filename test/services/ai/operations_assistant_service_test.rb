require "test_helper"

class Ai::OperationsAssistantServiceTest < ActiveSupport::TestCase
  test "builds the operational context and returns the AI answer" do
    target_date = Date.new(2026, 8, 1)
    question = "¿Cómo estuvo la operación de hoy?"

    context = {
      date: "2026-08-01",
      operational_metrics: {
        summary: {
          tickets_created: 25
        }
      }
    }

    prompt = {
      instructions: "Responde usando los datos.",
      input: "Contexto y pregunta operacional."
    }

    context_service_class = ContextServiceClassStub.new(context)
    prompt_builder_class = PromptBuilderClassStub.new(prompt)
    generation_client = GenerationClientStub.new(
      "La operación atendió 25 tickets."
    )

    result = Ai::OperationsAssistantService.new(
      date: target_date,
      question:,
      context_service_class:,
      prompt_builder_class:,
      generation_client:
    ).call

    assert_equal "La operación atendió 25 tickets.", result

    assert_equal(
      [ { date: target_date } ],
      context_service_class.received_arguments
    )

    assert_equal(
      [
        {
          question:,
          context:
        }
      ],
      prompt_builder_class.received_arguments
    )

    assert_equal(
      [ prompt ],
      generation_client.received_arguments
    )
  end

  private

  class ContextServiceClassStub
    attr_reader :received_arguments

    def initialize(context)
      @context = context
      @received_arguments = []
    end

    def new(date:)
      received_arguments << { date: }

      CallableStub.new(@context)
    end
  end

  class PromptBuilderClassStub
    attr_reader :received_arguments

    def initialize(prompt)
      @prompt = prompt
      @received_arguments = []
    end

    def new(question:, context:)
      received_arguments << {
        question:,
        context:
      }

      CallableStub.new(@prompt)
    end
  end

  class GenerationClientStub
    attr_reader :received_arguments

    def initialize(answer)
      @answer = answer
      @received_arguments = []
    end

    def call(**prompt)
      received_arguments << prompt
      @answer
    end
  end

  class CallableStub
    def initialize(result)
      @result = result
    end

    def call
      @result
    end
  end
end
