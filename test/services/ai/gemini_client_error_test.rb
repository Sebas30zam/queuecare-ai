require "test_helper"

class Ai::GeminiClientErrorTest < ActiveSupport::TestCase
  test "raises a descriptive error when Gemini rejects the request" do
    response = ResponseStub.new(
      code: "429",
      body: {
        error: {
          message: "Resource exhausted"
        }
      }.to_json
    )

    error = assert_raises(Ai::GeminiClient::Error) do
      build_client(response).call(
        instructions: "Analyze the operation.",
        input: "How was today?"
      )
    end

    assert_equal(
      "Gemini request failed (429): Resource exhausted",
      error.message
    )
  end

  test "raises a descriptive error when Gemini returns no generated text" do
    response = ResponseStub.new(
      code: "200",
      body: {
        candidates: []
      }.to_json
    )

    error = assert_raises(Ai::GeminiClient::Error) do
      build_client(response).call(
        instructions: "Analyze the operation.",
        input: "How was today?"
      )
    end

    assert_equal(
      "Gemini returned no generated text",
      error.message
    )
  end

  private

  def build_client(response)
    Ai::GeminiClient.new(
      api_key: "test-api-key",
      http_client: HttpClientStub.new(response)
    )
  end

  class HttpClientStub
    def initialize(response)
      @response = response
    end

    def start(_hostname, _port, use_ssl:)
      raise "SSL must be enabled" unless use_ssl

      yield self
    end

    def request(_request)
      @response
    end
  end

  ResponseStub = Data.define(:code, :body)
end
