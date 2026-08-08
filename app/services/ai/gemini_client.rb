require "net/http"

module Ai
  class GeminiClient
    class Error < StandardError; end

    DEFAULT_MODEL = "gemini-3.1-flash-lite"
    HOSTNAME = "generativelanguage.googleapis.com"
    PORT = 443
    RETRYABLE_STATUS_CODES = [ 429, 503 ].freeze
    MAX_RETRIES = 2
    RETRY_DELAY = 0.5

    def initialize(
      api_key: ENV.fetch("GEMINI_API_KEY"),
      model: DEFAULT_MODEL,
      http_client: Net::HTTP,
      sleeper: Kernel
    )
      @api_key = api_key
      @model = model
      @http_client = http_client
      @sleeper = sleeper
    end

    def call(instructions:, input:)
      request = build_request(
        instructions:,
        input:
      )

      retries = 0

      loop do
        response = send_request(request)

        if retryable?(response) && retries < MAX_RETRIES
          retries += 1
          sleeper.sleep(RETRY_DELAY * retries)
          next
        end

        return parse_response(response)
      end
    end

    private

    attr_reader :api_key, :model, :http_client, :sleeper

    def send_request(request)
      http_client.start(
        HOSTNAME,
        PORT,
        use_ssl: true
      ) do |http|
        http.request(request)
      end
    end

    def retryable?(response)
      RETRYABLE_STATUS_CODES.include?(response.code.to_i)
    end


    def build_request(instructions:, input:)
      request = Net::HTTP::Post.new(
        "/v1beta/models/#{model}:generateContent"
      )

      request["x-goog-api-key"] = api_key
      request["Content-Type"] = "application/json"

      request.body = {
        systemInstruction: {
          parts: [
            {
              text: instructions
            }
          ]
        },
        contents: [
          {
            role: "user",
            parts: [
              {
                text: input
              }
            ]
          }
        ]
      }.to_json

      request
    end

    def parse_response(response)
      body = JSON.parse(response.body)

      unless response.code.to_i.between?(200, 299)
        message = body.dig("error", "message") || "Unknown error"

        raise Error,
              "Gemini request failed (#{response.code}): #{message}"
      end

      generated_text = body.dig(
        "candidates",
        0,
        "content",
        "parts",
        0,
        "text"
      )

      if generated_text.to_s.strip.empty?
        raise Error, "Gemini returned no generated text"
      end

      generated_text
    end
  end
end
