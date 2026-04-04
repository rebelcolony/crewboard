require "test_helper"

class RenderingStatesTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    sign_in managers(:admin)
  end

  test "dashboard shows limit warning and upgrade link when project limit is reached" do
    get dashboard_path

    assert_response :success
    assert_match "Limit reached", response.body
    assert_match "Unassigned Crew (1)", response.body
    assert_match "Upgrade", response.body
  end

  test "dashboard shows unlimited indicators for pro accounts" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_render_pro"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_render_pro",
      processor_plan: "price_pro_test",
      status: "active"
    )

    get dashboard_path

    assert_response :success
    assert_match "Unlimited", response.body
    assert_no_match "Limit reached", response.body
  end

  test "admin subscriptions index shows empty state when there are no subscriptions" do
    get admin_subscriptions_path

    assert_response :success
    assert_match "No subscriptions yet.", response.body
  end

  test "project show renders inside the modal turbo frame" do
    get project_path(projects(:forties))

    assert_response :success
    assert_select "turbo-frame#modal"
    assert_match "Crew (1)", response.body
    assert_match "Callum MacLeod", response.body
  end

  test "project turbo stream update rerenders the modal and project card" do
    patch project_path(projects(:forties)),
      params: { project: { progress: 80 } },
      headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_match %{target="modal"}, response.body
    assert_match %{target="#{dom_id(projects(:forties))}"}, response.body
  end

  test "crew member turbo stream update rerenders unassigned bar and project card" do
    patch crew_member_path(crew_members(:unassigned_isla)),
      params: { crew_member: { project_id: projects(:forties).id } },
      headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_match %{target="unassigned-crew"}, response.body
    assert_match "All crew members assigned", response.body
    assert_match %{target="#{dom_id(projects(:forties))}"}, response.body
  end
end
