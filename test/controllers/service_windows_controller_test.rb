require "test_helper"

class ServiceWindowsControllerTest < ActionDispatch::IntegrationTest
  test "admin can open new service window form" do
    login_as(users(:admin_user))

    get new_service_window_url

    assert_response :success
    assert_equal "service-windows/new", inertia_page.fetch("component")
    assert inertia_props.fetch("queue_services").any?
  end

  test "supervisor can open new service window form" do
    login_as(users(:supervisor_user))

    get new_service_window_url

    assert_response :success
    assert_equal "service-windows/new", inertia_page.fetch("component")
  end

  test "admin can create service window" do
    login_as(users(:admin_user))

    assert_difference("ServiceWindow.count", 1) do
      post service_windows_url, params: {
        service_window: {
          name: "Window 10",
          code: "w10",
          queue_service_id: queue_services(:admissions).id,
          active: true
        }
      }
    end

    service_window = ServiceWindow.find_by!(code: "W10")

    assert_equal "Window 10", service_window.name
    assert_equal queue_services(:admissions), service_window.queue_service
    assert service_window.active?
    assert_redirected_to service_windows_url
    assert_equal "Service window created successfully.", flash[:notice]
  end

  test "supervisor can create service window" do
    login_as(users(:supervisor_user))

    assert_difference("ServiceWindow.count", 1) do
      post service_windows_url, params: {
        service_window: {
          name: "Supervisor Window",
          code: "sw1",
          queue_service_id: queue_services(:finance).id,
          active: true
        }
      }
    end

    service_window = ServiceWindow.find_by!(code: "SW1")

    assert_equal "Supervisor Window", service_window.name
    assert_redirected_to service_windows_url
  end

  test "receptionist cannot create service window" do
    login_as(users(:receptionist_user))

    assert_no_difference("ServiceWindow.count") do
      post service_windows_url, params: {
        service_window: {
          name: "Unauthorized Window",
          code: "UW1",
          queue_service_id: queue_services(:admissions).id,
          active: true
        }
      }
    end

    assert_redirected_to root_url
  end

  test "invalid data does not create service window" do
    login_as(users(:admin_user))

    assert_no_difference("ServiceWindow.count") do
      post service_windows_url, params: {
        service_window: {
          name: "",
          code: "",
          queue_service_id: "",
          active: true
        }
      }
    end

    assert_response :unprocessable_entity
    assert_equal "service-windows/new", inertia_page.fetch("component")
  end

  test "service window must belong to queue service" do
    login_as(users(:admin_user))

    assert_no_difference("ServiceWindow.count") do
      post service_windows_url, params: {
        service_window: {
          name: "Missing Service Window",
          code: "MSW",
          queue_service_id: "",
          active: true
        }
      }
    end

    assert_response :unprocessable_entity
    assert inertia_props.fetch("errors").key?("queue_service_id")
  end

  test "duplicate code is rejected" do
    login_as(users(:admin_user))

    assert_no_difference("ServiceWindow.count") do
      post service_windows_url, params: {
        service_window: {
          name: "Duplicate Window",
          code: "w1",
          queue_service_id: queue_services(:finance).id,
          active: true
        }
      }
    end

    assert_response :unprocessable_entity
    assert inertia_props.fetch("errors").key?("code")
  end

  test "admin can open edit service window form" do
    login_as(users(:admin_user))

    get edit_service_window_url(service_windows(:window_one))

    assert_response :success
    assert_equal "service-windows/edit", inertia_page.fetch("component")
  end

  test "supervisor can open edit service window form" do
    login_as(users(:supervisor_user))

    get edit_service_window_url(service_windows(:window_one))

    assert_response :success
  end

  test "admin can update service window" do
    login_as(users(:admin_user))

    patch service_window_url(service_windows(:window_one)), params: {
      service_window: {
        name: "Updated Window",
        code: "w1",
        queue_service_id: queue_services(:finance).id,
        active: true
      }
    }

    assert_redirected_to service_windows_url

    service_window = service_windows(:window_one).reload

    assert_equal "Updated Window", service_window.name
    assert_equal queue_services(:finance), service_window.queue_service
  end

  test "supervisor can update service window" do
    login_as(users(:supervisor_user))

    patch service_window_url(service_windows(:window_two)), params: {
      service_window: {
        name: "Supervisor Updated Window",
        code: "w2",
        queue_service_id: queue_services(:finance).id,
        active: false
      }
    }

    assert_redirected_to service_windows_url

    service_window = service_windows(:window_two).reload

    assert_equal "Supervisor Updated Window", service_window.name
    assert_not service_window.active?
  end

  test "invalid update does not persist" do
    login_as(users(:admin_user))

    service_window = service_windows(:window_one)
    original_name = service_window.name

    patch service_window_url(service_window), params: {
      service_window: {
        name: "",
        code: "",
        queue_service_id: "",
        active: true
      }
    }

    assert_response :unprocessable_entity
    assert_equal original_name, service_window.reload.name
  end

  test "admin can delete unused service window" do
    login_as(users(:admin_user))

    service_window = ServiceWindow.create!(
      name: "Disposable Window",
      code: "DW1",
      queue_service: queue_services(:admissions),
      active: true
    )

    assert_difference("ServiceWindow.count", -1) do
      delete service_window_url(service_window)
    end

    assert_redirected_to service_windows_url
    assert_equal "Service window deleted successfully.", flash[:notice]
  end

  test "supervisor can delete unused service window" do
    login_as(users(:supervisor_user))

    service_window = ServiceWindow.create!(
      name: "Supervisor Disposable Window",
      code: "SDW",
      queue_service: queue_services(:finance),
      active: true
    )

    assert_difference("ServiceWindow.count", -1) do
      delete service_window_url(service_window)
    end

    assert_redirected_to service_windows_url
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
