module Ai
  class OpenaiResponsesClient
    DEFAULT_MODEL = "gpt-5.6"

    def initialize(
      client: OpenAI::Client.new,
      model: DEFAULT_MODEL
    )
      @client = client
      @model = model
    end

    def call(instructions:, input:)
      response = client.responses.create(
        model:,
        instructions:,
        input:
      )

      response.output_text
    end

    private

    attr_reader :client, :model
  end
end
