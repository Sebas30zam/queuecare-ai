require "test_helper"

class PublicScreensControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 6, 12, 14, 0, 0)

    @queue_service = queue_services(:admissions)
    @service_window = service_windows(:window_one)
    @assigned_agent = users(:agent_user)

    @called_ticket = create_ticket(
      status: "called",
      daily_sequence: 101,
      called_at: 2.minutes.ago
    )

    @in_attention_ticket = create_ticket(
      status: "in_attention",
      daily_sequence: 102,
      called_at: 5.minutes.ago,
      started_at: 1.minute.ago
    )

    @pending_ticket = create_ticket(
      status: "pending",
      daily_sequence: 103
    )

    @attended_ticket = create_ticket(
      status: "attended",
      daily_sequence: 104,
      called_at: 20.minutes.ago,
      started_at: 15.minutes.ago,
      finished_at: 5.minutes.ago
    )

    @no_show_ticket = create_ticket(
      status: "no_show",
      daily_sequence: 105,
      called_at: 20.minutes.ago,
      no_show_at: 5.minutes.ago
    )

    @cancelled_ticket = create_ticket(
      status: "cancelled",
      daily_sequence: 106
    )
  end

  teardown do
    travel_back
  end

  test "public screen is accessible without login" do
    get public_screen_url

    assert_response :success
  end

  test "returns success" do
    get public_screen_url

    assert_response :success
    assert_equal "public-screen/index", inertia_page.fetch("component")
  end

  test "includes called tickets" do
    get public_screen_url

    assert_includes active_ticket_ids, @called_ticket.id
  end

  test "includes in attention tickets" do
    get public_screen_url

    assert_includes active_ticket_ids, @in_attention_ticket.id
  end

  test "does not include pending tickets" do
    get public_screen_url

    assert_not_includes active_ticket_ids, @pending_ticket.id
  end

  test "does not include attended tickets" do
    get public_screen_url

    assert_not_includes active_ticket_ids, @attended_ticket.id
  end

  test "does not include no show tickets" do
    get public_screen_url

    assert_not_includes active_ticket_ids, @no_show_ticket.id
  end

  test "does not include cancelled tickets" do
    get public_screen_url

    assert_not_includes active_ticket_ids, @cancelled_ticket.id
  end

  test "includes previously called completed tickets in recently called" do
    get public_screen_url

    assert_includes recently_called_ticket_ids, @attended_ticket.id
    assert_includes recently_called_ticket_ids, @no_show_ticket.id
  end

  test "does not include tickets that were never called in recently called" do
    get public_screen_url

    assert_not_includes recently_called_ticket_ids, @pending_ticket.id
    assert_not_includes recently_called_ticket_ids, @cancelled_ticket.id
  end

  private

  def create_ticket(status:, daily_sequence:, **timestamps)
    Ticket.create!(
      queue_service: @queue_service,
      service_window: @service_window,
      assigned_agent: @assigned_agent,
      ticket_number: format("PUB-%03d", daily_sequence),
      sequence_date: Date.current,
      daily_sequence: daily_sequence,
      priority: "normal",
      priority_weight: 6,
      status: status,
      intake_source: "self_service",
      **timestamps
    )
  end

  def inertia_page
    page_element = Nokogiri::HTML(response.body).at_css(
      'script[data-page="app"]'
    )

    raise "Inertia page data was not found" unless page_element

    JSON.parse(page_element.text)
  end

  def active_ticket_ids
    inertia_page
      .fetch("props")
      .fetch("active_tickets")
      .pluck("id")
  end

  def recently_called_ticket_ids
    inertia_page
      .fetch("props")
      .fetch("recently_called_tickets")
      .pluck("id")
  end
end
