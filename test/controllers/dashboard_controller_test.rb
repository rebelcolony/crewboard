require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "authenticated user sees dashboard" do
    sign_in managers(:admin)
    get root_path
    assert_response :success
    assert_select ".dashboard"
  end

  test "unauthenticated user is redirected to login" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "dashboard only shows current tenant projects" do
    sign_in managers(:admin)
    get root_path
    assert_response :success
    assert_match "Forties Alpha Inspection", response.body
    assert_no_match "Deepwater Horizon Survey", response.body
  end
end
