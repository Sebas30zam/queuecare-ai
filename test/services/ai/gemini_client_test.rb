require "test_helper"

class Ai::GeminiClientTest < ActiveSupport::TestCase
  test "sends the prompt to Gemini and returns the generated text" do
    response = ResponseStub.new(
      code: "200",
      body: {
        candidates: [
          {
            content: {
              parts: [
                {
                  text: "La operación atendió 25 tickets."
                }
              ]
            }
          }
        ]
      }.to_json
    )

    http_client = HttpClientStub.new(response)

    result = Ai::GeminiClient.new(
      api_key: "test-api-key",
      model: "gemini-2.5-flash-lite",
      http_client:
    ).call(
      instructions: "Responde usando únicamente los datos.",
      input: "Analiza la operación de hoy."
    )

    assert_equal "La operación atendió 25 tickets.", result

    assert_equal(
      "generativelanguage.googleapis.com",
      http_client.hostname
    )

    assert_equal 443, http_client.port
    assert http_client.use_ssl

    request = http_client.received_request

    assert_equal "test-api-key", request["x-goog-api-key"]
    assert_equal "application/json", request["Content-Type"]

    assert_equal(
      "/v1beta/models/gemini-2.5-flash-lite:generateContent",
      request.path
    )

    assert_equal(
      {
        "systemInstruction" => {
          "parts" => [
            {
              "text" => "Responde usando únicamente los datos."
            }
          ]
        },
        "contents" => [
          {
            "role" => "user",
            "parts" => [
              {
                "text" => "Analiza la operación de hoy."
              }
            ]
          }
        ]
      },
      JSON.parse(request.body)
    )
  end

  private

  class HttpClientStub
    attr_reader :hostname, :port, :use_ssl, :received_request

    def initialize(response)
      @response = response
    end

    def start(hostname, port, use_ssl:)
      @hostname = hostname
      @port = port
      @use_ssl = use_ssl

      yield self
    end

    def request(request)
      @received_request = request
      @response
    end
  end

  ResponseStub = Data.define(:code, :body)
end
