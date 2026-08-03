require "test_helper"

class Ai::OpenaiResponsesClientTest < ActiveSupport::TestCase
  test "sends the prompt to the Responses API and returns its text" do
    response = ResponseStub.new(
      "La operación presenta un tiempo de espera elevado."
    )

    responses = ResponsesStub.new(response)
    client = ClientStub.new(responses)

    result = Ai::OpenaiResponsesClient.new(
      client:,
      model: "gpt-5.6"
    ).call(
      instructions: "Responde usando únicamente los datos.",
      input: "Analiza la operación de hoy."
    )

    assert_equal(
      "La operación presenta un tiempo de espera elevado.",
      result
    )

    assert_equal(
      [
        {
          model: "gpt-5.6",
          instructions:
            "Responde usando únicamente los datos.",
          input: "Analiza la operación de hoy."
        }
      ],
      responses.received_arguments
    )
  end

  private

  class ClientStub
    attr_reader :responses

    def initialize(responses)
      @responses = responses
    end
  end

  class ResponsesStub
    attr_reader :received_arguments

    def initialize(response)
      @response = response
      @received_arguments = []
    end

    def create(**arguments)
      received_arguments << arguments
      @response
    end
  end

  class ResponseStub
    attr_reader :output_text

    def initialize(output_text)
      @output_text = output_text
    end
  end
end
