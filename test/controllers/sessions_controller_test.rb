require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get login page" do
    get login_url

    assert_response :success
  end

  test "should create session with valid credentials" do
    post login_url, params: {
      email: "admin@test.com",
      password: "password123"
    }

    assert_redirected_to root_url
  end

  test "should destroy session" do
    delete logout_url

    assert_redirected_to login_url
  end
end
