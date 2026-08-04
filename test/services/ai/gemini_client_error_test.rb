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

  test "retries a temporary error and returns the generated text" do
    responses = [
      ResponseStub.new(
        code: "503",
        body: {
          error: {
            message: "High demand"
          }
        }.to_json
      ),
      ResponseStub.new(
        code: "200",
        body: {
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: "The operation is stable."
                  }
                ]
              }
            }
          ]
        }.to_json
      )
    ]

    http_client = HttpClientStub.new(responses)
    sleeper = SleeperStub.new

    result = Ai::GeminiClient.new(
      api_key: "test-api-key",
      http_client:,
      sleeper:
    ).call(
      instructions: "Analyze the operation.",
      input: "How was today?"
    )

    assert_equal "The operation is stable.", result
    assert_equal 2, http_client.request_count
    assert_equal [ 0.5 ], sleeper.delays
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
      http_client: HttpClientStub.new(response),
      sleeper: SleeperStub.new
    )
  end

  class HttpClientStub
    attr_reader :request_count

    def initialize(responses)
      @responses = responses.is_a?(Array) ? responses : [ responses ]
      @request_count = 0
    end

    def start(_hostname, _port, use_ssl:)
      raise "SSL must be enabled" unless use_ssl

      yield self
    end

    def request(_request)
      response = @responses.fetch(
        [ request_count, @responses.length - 1 ].min
      )

      @request_count += 1
      response
    end
  end

  class SleeperStub
    attr_reader :delays

    def initialize
      @delays = []
    end

    def sleep(delay)
      delays << delay
    end
  end

  ResponseStub = Data.define(:code, :body)
end
