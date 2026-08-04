require "test_helper"

class Ai::OperationsPromptBuilderTest < ActiveSupport::TestCase
  test "builds instructions and input from the operational context" do
    context = {
      date: "2026-08-01",
      operational_metrics: {
        summary: {
          tickets_created: 25,
          tickets_attended: 20
        }
      }
    }

    result = Ai::OperationsPromptBuilder.new(
      question: "¿Cómo estuvo la operación de hoy?",
      context:
    ).call

    assert_includes result[:instructions], "QueueCare AI"
    assert_includes result[:instructions], "datos proporcionados"
    assert_includes result[:instructions], "mismo idioma de la pregunta"
    assert_includes result[:input], "2026-08-01"
    assert_includes result[:input], "tickets_created"
    assert_includes result[:input], "¿Cómo estuvo la operación de hoy?"
  end

  test "rejects an empty question" do
    error = assert_raises(ArgumentError) do
      Ai::OperationsPromptBuilder.new(
        question: "   ",
        context: {}
      ).call
    end

    assert_equal "Question cannot be blank", error.message
  end

  test "rejects a question longer than the allowed limit" do
    error = assert_raises(ArgumentError) do
      Ai::OperationsPromptBuilder.new(
        question: "a" * 1_001,
        context: {}
      ).call
    end

    assert_equal(
      "Question cannot exceed 1000 characters",
      error.message
    )
  end
end
