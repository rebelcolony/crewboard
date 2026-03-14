require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "authenticated user sees dashboard" do
    sign_in managers(:admin)
    get dashboard_path
    assert_response :success
    assert_select ".dashboard"
  end

  test "unauthenticated user is redirected to login" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "dashboard only shows current tenant projects" do
    sign_in managers(:admin)
    get dashboard_path
    assert_response :success
    assert_match "Forties Alpha Inspection", response.body
    assert_no_match "Deepwater Horizon Survey", response.body
  end

  test "dashboard shows usage indicators" do
    sign_in managers(:admin)
    get dashboard_path
    assert_response :success
    assert_select ".usage-bar"
    assert_select ".usage-indicator", count: 2
    assert_select ".usage-count", /2.*\/.*2/  # projects: 2 / 2
    assert_select ".badge", /Free/
  end
end
