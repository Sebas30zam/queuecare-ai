require "test_helper"

class QueueServicesControllerTest < ActionDispatch::IntegrationTest
  test "admin can open new queue service form" do
    login_as(users(:admin_user))

    get new_queue_service_url

    assert_response :success
    assert_equal "queue-services/new", inertia_page.fetch("component")
  end

  test "supervisor can open new queue service form" do
    login_as(users(:supervisor_user))

    get new_queue_service_url

    assert_response :success
    assert_equal "queue-services/new", inertia_page.fetch("component")
  end

  test "admin can create queue service" do
    login_as(users(:admin_user))

    assert_difference("QueueService.count", 1) do
      post queue_services_url, params: {
        queue_service: {
          name: "Academic Support",
          code: "acs",
          estimated_attention_minutes: 18,
          active: true
        }
      }
    end

    queue_service = QueueService.find_by!(code: "ACS")

    assert_equal "Academic Support", queue_service.name
    assert_equal 18, queue_service.estimated_attention_minutes
    assert queue_service.active?
    assert_redirected_to queue_services_url
    assert_equal "Queue service created successfully.", flash[:notice]
  end

  test "supervisor can create queue service" do
    login_as(users(:supervisor_user))

    assert_difference("QueueService.count", 1) do
      post queue_services_url, params: {
        queue_service: {
          name: "Supervisor Service",
          code: "sup",
          estimated_attention_minutes: 11,
          active: true
        }
      }
    end

    queue_service = QueueService.find_by!(code: "SUP")

    assert_equal "Supervisor Service", queue_service.name
    assert_redirected_to queue_services_url
  end

  test "receptionist cannot create queue service" do
    login_as(users(:receptionist_user))

    assert_no_difference("QueueService.count") do
      post queue_services_url, params: {
        queue_service: {
          name: "Unauthorized Service",
          code: "UNA",
          estimated_attention_minutes: 10,
          active: true
        }
      }
    end

    assert_redirected_to root_url
  end

  test "invalid data does not create queue service" do
    login_as(users(:admin_user))

    assert_no_difference("QueueService.count") do
      post queue_services_url, params: {
        queue_service: {
          name: "",
          code: "",
          estimated_attention_minutes: "",
          active: true
        }
      }
    end

    assert_response :unprocessable_entity
    assert_equal "queue-services/new", inertia_page.fetch("component")
  end

  test "duplicate code is rejected" do
    login_as(users(:admin_user))

    assert_no_difference("QueueService.count") do
      post queue_services_url, params: {
        queue_service: {
          name: "Duplicate Admissions",
          code: "adm",
          estimated_attention_minutes: 12,
          active: true
        }
      }
    end

    assert_response :unprocessable_entity
    assert inertia_props.fetch("errors").key?("code")
  end

  test "admin can open edit queue service form" do
    login_as(users(:admin_user))

    get edit_queue_service_url(queue_services(:admissions))

    assert_response :success
    assert_equal "queue-services/edit", inertia_page.fetch("component")
  end

  test "supervisor can open edit queue service form" do
    login_as(users(:supervisor_user))

    get edit_queue_service_url(queue_services(:admissions))

    assert_response :success
  end

  test "admin can update queue service" do
    login_as(users(:admin_user))

    patch queue_service_url(queue_services(:admissions)), params: {
      queue_service: {
        name: "Updated Admissions",
        code: "adm",
        estimated_attention_minutes: 20,
        active: true
      }
    }

    assert_redirected_to queue_services_url

    queue_service = queue_services(:admissions).reload

    assert_equal "Updated Admissions", queue_service.name
    assert_equal 20, queue_service.estimated_attention_minutes
  end

  test "supervisor can update queue service" do
    login_as(users(:supervisor_user))

    patch queue_service_url(queue_services(:finance)), params: {
      queue_service: {
        name: "Updated Finance",
        code: "fin",
        estimated_attention_minutes: 17,
        active: false
      }
    }

    assert_redirected_to queue_services_url

    queue_service = queue_services(:finance).reload

    assert_equal "Updated Finance", queue_service.name
    assert_equal 17, queue_service.estimated_attention_minutes
    assert_not queue_service.active?
  end

  test "invalid update does not persist" do
    login_as(users(:admin_user))

    queue_service = queue_services(:admissions)
    original_name = queue_service.name

    patch queue_service_url(queue_service), params: {
      queue_service: {
        name: "",
        code: "",
        estimated_attention_minutes: 0,
        active: true
      }
    }

    assert_response :unprocessable_entity
    assert_equal original_name, queue_service.reload.name
  end

  test "admin can delete unused queue service" do
    login_as(users(:admin_user))

    queue_service = QueueService.create!(
      name: "Disposable Service",
      code: "DSP",
      estimated_attention_minutes: 10,
      active: true
    )

    assert_difference("QueueService.count", -1) do
      delete queue_service_url(queue_service)
    end

    assert_redirected_to queue_services_url
    assert_equal "Queue service deleted successfully.", flash[:notice]
  end

  test "supervisor can delete unused queue service" do
    login_as(users(:supervisor_user))

    queue_service = QueueService.create!(
      name: "Supervisor Disposable Service",
      code: "SDS",
      estimated_attention_minutes: 9,
      active: true
    )

    assert_difference("QueueService.count", -1) do
      delete queue_service_url(queue_service)
    end

    assert_redirected_to queue_services_url
  end

  test "service with related windows cannot be deleted" do
    login_as(users(:admin_user))

    queue_service = queue_services(:admissions)

    assert_no_difference("QueueService.count") do
      delete queue_service_url(queue_service)
    end

    assert_redirected_to queue_services_url
    assert_equal(
      "This service cannot be deleted because it has related operational records.",
      flash[:alert]
    )
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
