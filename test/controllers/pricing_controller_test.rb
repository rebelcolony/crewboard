require "test_helper"

class PricingControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated user can view pricing page" do
    get pricing_path
    assert_response :success
    assert_match "Choose Your Plan", response.body
  end

  test "authenticated user can view pricing page" do
    sign_in managers(:admin)
    get pricing_path
    assert_response :success
    assert_match "Choose Your Plan", response.body
  end

  test "pricing page shows all three plans" do
    get pricing_path
    assert_response :success
    assert_match "Starter", response.body
    assert_match "Pro", response.body
    assert_match "Enterprise", response.body
  end

  test "unauthenticated user sees registration links" do
    get pricing_path
    assert_response :success
    assert_match "Get Started", response.body
    assert_no_match "Subscribe", response.body
  end

  test "authenticated user sees subscribe buttons" do
    sign_in managers(:admin)
    get pricing_path
    assert_response :success
    assert_match "Subscribe", response.body
  end
end
