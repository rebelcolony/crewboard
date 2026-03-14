require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET root shows landing page for unauthenticated visitors" do
    get root_path
    assert_response :success
    assert_match "CrewBoard", response.body
    assert_match "Get Started", response.body
  end

  test "GET root redirects authenticated users to dashboard" do
    sign_in managers(:admin)
    get root_path
    assert_redirected_to dashboard_path
  end
end
