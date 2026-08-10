require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user is redirected to login" do
    get root_url

    assert_redirected_to login_url
  end

  test "admin is redirected to dashboard" do
    login_as(users(:admin_user))

    get root_url

    assert_redirected_to dashboard_url
  end

  test "supervisor is redirected to dashboard" do
    login_as(users(:supervisor_user))

    get root_url

    assert_redirected_to dashboard_url
  end

  test "receptionist is redirected to assisted intake" do
    login_as(users(:receptionist_user))

    get root_url

    assert_redirected_to tickets_reception_url
  end

  test "agent is redirected to agent queue" do
    login_as(users(:agent_user))

    get root_url

    assert_redirected_to agent_queue_url
  end

  private

  def login_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end
end
