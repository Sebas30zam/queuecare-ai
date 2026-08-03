require "net/http"

module Ai
  class GeminiClient
    class Error < StandardError; end

    DEFAULT_MODEL = "gemini-2.5-flash-lite"
    HOSTNAME = "generativelanguage.googleapis.com"
    PORT = 443

    def initialize(
      api_key: ENV.fetch("GEMINI_API_KEY"),
      model: DEFAULT_MODEL,
      http_client: Net::HTTP
    )
      @api_key = api_key
      @model = model
      @http_client = http_client
    end

    def call(instructions:, input:)
      request = build_request(
        instructions:,
        input:
      )

      response = http_client.start(
        HOSTNAME,
        PORT,
        use_ssl: true
      ) do |http|
        http.request(request)
      end

      parse_response(response)
    end

    private

    attr_reader :api_key, :model, :http_client

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
