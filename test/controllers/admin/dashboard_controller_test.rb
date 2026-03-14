require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "super admin can access admin dashboard" do
    sign_in managers(:admin)
    get admin_root_path
    assert_response :success
    assert_match "Admin Dashboard", response.body
  end

  test "regular manager is redirected from admin" do
    sign_in managers(:regular)
    get admin_root_path
    assert_redirected_to root_path
  end

  test "unauthenticated user is redirected to login" do
    get admin_root_path
    assert_redirected_to new_session_path
  end

  test "admin dashboard shows cross-tenant stats" do
    sign_in managers(:admin)
    get admin_root_path
    assert_response :success
    # Should show counts from all tenants
    assert_select ".stat-card", minimum: 2
  end
end
