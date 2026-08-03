module Ai
  class OperationsAssistantService
    def initialize(
      date:,
      question:,
      context_service_class: OperationsContextService,
      prompt_builder_class: OperationsPromptBuilder,
      responses_client: OpenaiResponsesClient.new
    )
      @date = date
      @question = question
      @context_service_class = context_service_class
      @prompt_builder_class = prompt_builder_class
      @responses_client = responses_client
    end

    def call
      context = context_service_class
        .new(date:)
        .call

      prompt = prompt_builder_class
        .new(question:, context:)
        .call

      responses_client.call(**prompt)
    end

    private

    attr_reader :date,
                :question,
                :context_service_class,
                :prompt_builder_class,
                :responses_client
  end
end
