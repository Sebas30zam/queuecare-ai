require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin sees admin users in index" do
    login_as(users(:admin_user))

    get users_url

    assert_response :success

    user_roles =
      inertia_props
        .fetch("users")
        .map { |user| user.fetch("role") }

    assert_includes user_roles, "admin"
  end

  test "supervisor does not see admin users in index" do
    login_as(users(:supervisor_user))

    get users_url

    assert_response :success

    user_roles =
      inertia_props
        .fetch("users")
        .map { |user| user.fetch("role") }

    assert_not_includes user_roles, "admin"
  end

  test "admin can open new user form with admin role available" do
    login_as(users(:admin_user))

    get new_user_url

    assert_response :success

    roles = inertia_props.fetch("roles").map { |role| role.fetch("name") }

    assert_includes roles, "admin"
    assert_includes roles, "supervisor"
    assert_includes roles, "receptionist"
    assert_includes roles, "agent"
  end

  test "supervisor can open new user form without admin role" do
    login_as(users(:supervisor_user))

    get new_user_url

    assert_response :success

    roles = inertia_props.fetch("roles").map { |role| role.fetch("name") }

    assert_not_includes roles, "admin"
    assert_includes roles, "supervisor"
    assert_includes roles, "receptionist"
    assert_includes roles, "agent"
  end

  test "supervisor can create non admin user" do
    login_as(users(:supervisor_user))

    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "New Agent",
          email: "new.agent@test.com",
          password: "password123",
          password_confirmation: "password123",
          role_id: roles(:agent).id,
          active: true
        }
      }
    end

    assert_redirected_to users_url
    assert_equal "agent", User.find_by!(email: "new.agent@test.com").role.name
  end

  test "supervisor cannot create admin user" do
    login_as(users(:supervisor_user))

    assert_no_difference("User.count") do
      post users_url, params: {
        user: {
          name: "Forbidden Admin",
          email: "forbidden.admin@test.com",
          password: "password123",
          password_confirmation: "password123",
          role_id: roles(:admin).id,
          active: true
        }
      }
    end

    assert_response :unprocessable_entity
    assert inertia_props.fetch("errors").key?("role_id")
  end

  test "admin can edit user" do
    login_as(users(:admin_user))

    get edit_user_url(users(:agent_user))

    assert_response :success
    assert_equal "users/edit", inertia_page.fetch("component")
  end

  test "supervisor can edit non admin user" do
    login_as(users(:supervisor_user))

    get edit_user_url(users(:agent_user))

    assert_response :success
  end

  test "supervisor cannot edit admin user" do
    login_as(users(:supervisor_user))

    get edit_user_url(users(:admin_user))

    assert_redirected_to users_url
    assert_equal "You are not authorized to manage this user.", flash[:alert]
  end

  test "admin can update user" do
    login_as(users(:admin_user))

    patch user_url(users(:agent_user)), params: {
      user: {
        name: "Updated Agent",
        email: users(:agent_user).email,
        password: "",
        password_confirmation: "",
        role_id: roles(:agent).id,
        active: true
      }
    }

    assert_redirected_to users_url
    assert_equal "Updated Agent", users(:agent_user).reload.name
  end

  test "supervisor can update non admin user" do
    login_as(users(:supervisor_user))

    patch user_url(users(:agent_user)), params: {
      user: {
        name: "Supervisor Updated Agent",
        email: users(:agent_user).email,
        password: "",
        password_confirmation: "",
        role_id: roles(:agent).id,
        active: true
      }
    }

    assert_redirected_to users_url
    assert_equal(
      "Supervisor Updated Agent",
      users(:agent_user).reload.name
    )
  end

  test "supervisor cannot update admin user" do
    login_as(users(:supervisor_user))

    original_name = users(:admin_user).name

    patch user_url(users(:admin_user)), params: {
      user: {
        name: "Changed Admin",
        email: users(:admin_user).email,
        password: "",
        password_confirmation: "",
        role_id: roles(:admin).id,
        active: true
      }
    }

    assert_redirected_to users_url
    assert_equal original_name, users(:admin_user).reload.name
  end

  test "admin can delete another user without protected records" do
    login_as(users(:admin_user))

    disposable_user = User.create!(
      name: "Disposable User",
      email: "disposable@test.com",
      password: "password123",
      password_confirmation: "password123",
      role: roles(:receptionist),
      active: true
    )

    assert_difference("User.count", -1) do
      delete user_url(disposable_user)
    end

    assert_redirected_to users_url
    assert_equal "User deleted successfully.", flash[:notice]
  end

  test "supervisor can delete non admin user" do
    login_as(users(:supervisor_user))

    disposable_user = User.create!(
      name: "Supervisor Disposable User",
      email: "supervisor.disposable@test.com",
      password: "password123",
      password_confirmation: "password123",
      role: roles(:agent),
      active: true
    )

    assert_difference("User.count", -1) do
      delete user_url(disposable_user)
    end

    assert_redirected_to users_url
  end

  test "supervisor cannot delete admin user" do
    login_as(users(:supervisor_user))

    assert_no_difference("User.count") do
      delete user_url(users(:admin_user))
    end

    assert_redirected_to users_url
    assert User.exists?(users(:admin_user).id)
  end

  test "user cannot delete own account" do
    login_as(users(:admin_user))

    assert_no_difference("User.count") do
      delete user_url(users(:admin_user))
    end

    assert_redirected_to users_url
    assert_equal "You cannot delete your own account.", flash[:alert]
  end

  test "receptionist cannot access users" do
    login_as(users(:receptionist_user))

    get users_url

    assert_redirected_to root_url
  end

  test "invalid update does not persist" do
    login_as(users(:admin_user))

    original_email = users(:agent_user).email

    patch user_url(users(:agent_user)), params: {
      user: {
        name: "",
        email: "",
        password: "",
        password_confirmation: "",
        role_id: roles(:agent).id,
        active: true
      }
    }

    assert_response :unprocessable_entity
    assert_equal original_email, users(:agent_user).reload.email
  end

  private

  def login_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }

    assert_redirected_to root_url
  end

  def inertia_page
    page_element = Nokogiri::HTML(response.body).at_css(
      'script[data-page="app"]'
    )

    raise "Inertia page data was not found" unless page_element

    JSON.parse(page_element.text)
  end

  def inertia_props
    inertia_page.fetch("props")
  end
end
