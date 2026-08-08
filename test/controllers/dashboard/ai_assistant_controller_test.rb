require "test_helper"

module Dashboard
  class AiAssistantControllerTest < ActionDispatch::IntegrationTest
    include ActiveSupport::Testing::TimeHelpers

    GEMINI_URL = %r{
      \Ahttps://generativelanguage\.googleapis\.com/
      v1beta/models/[^/]+:generateContent\z
    }x

    setup do
      @previous_gemini_api_key = ENV["GEMINI_API_KEY"]
      ENV["GEMINI_API_KEY"] = "test-gemini-api-key"

      travel_to Time.zone.local(2026, 6, 15, 12, 0, 0)
    end

    teardown do
      if @previous_gemini_api_key
        ENV["GEMINI_API_KEY"] = @previous_gemini_api_key
      else
        ENV.delete("GEMINI_API_KEY")
      end

      travel_back
    end

    test "unauthenticated user is redirected" do
      post dashboard_ai_assistant_url,
           params: {
             question: "How is the operation performing today?"
           }

      assert_redirected_to login_url
    end

    test "admin receives an AI assistant answer" do
      login_as(users(:admin_user))
      stub_gemini_success("The operation is performing normally.")

      post dashboard_ai_assistant_url,
           params: {
             question: "How is the operation performing today?"
           }

      assert_response :success
      assert_equal(
        "The operation is performing normally.",
        response_json.fetch("answer")
      )
      assert_requested(:post, GEMINI_URL, times: 1)
    end

    test "supervisor receives an AI assistant answer" do
      login_as(users(:supervisor_user))
      stub_gemini_success("General Support needs attention.")

      post dashboard_ai_assistant_url,
           params: {
             question: "Which service needs attention?"
           }

      assert_response :success
      assert_equal(
        "General Support needs attention.",
        response_json.fetch("answer")
      )
      assert_requested(:post, GEMINI_URL, times: 1)
    end

    test "receptionist cannot access AI assistant" do
      login_as(users(:receptionist_user))

      post dashboard_ai_assistant_url,
           params: {
             question: "How is the operation performing today?"
           }

      assert_redirected_to root_url
      assert_equal(
        "You are not authorized to access this page.",
        flash[:alert]
      )
    end

    test "blank question returns unprocessable entity" do
      login_as(users(:admin_user))

      post dashboard_ai_assistant_url,
           params: {
             question: "   "
           }

      assert_response :unprocessable_entity
      assert_equal(
        "Question is required.",
        response_json.fetch("error")
      )
    end

    test "Gemini failure returns bad gateway" do
      login_as(users(:admin_user))
      stub_gemini_failure

      post dashboard_ai_assistant_url,
           params: {
             question: "How is the operation performing today?"
           }

      assert_response :bad_gateway
      assert_equal(
        "The AI assistant is temporarily unavailable.",
        response_json.fetch("error")
      )
      assert_requested(:post, GEMINI_URL, times: 3)
    end

    private

    def login_as(user)
      post login_url, params: {
        email: user.email,
        password: "password123"
      }

      assert_redirected_to root_url
    end

    def stub_gemini_success(answer)
      stub_request(:post, GEMINI_URL).to_return(
        status: 200,
        body: {
          candidates: [
            {
              content: {
                parts: [
                  {
                    text: answer
                  }
                ]
              }
            }
          ]
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )
    end

    def stub_gemini_failure
      stub_request(:post, GEMINI_URL).to_return(
        status: 503,
        body: {
          error: {
            message: "Simulated Gemini failure"
          }
        }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )
    end

    def response_json
      JSON.parse(response.body)
    end
  end
end
