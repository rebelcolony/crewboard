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

  test "starter plan shows current plan and upgrade path" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_pricing_starter"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_pricing_starter",
      processor_plan: "price_starter_test",
      status: "active"
    )

    sign_in managers(:admin)
    get pricing_path

    assert_response :success
    assert_match "Current Plan", response.body
    assert_match "Upgrade to Pro", response.body
    assert_match "Up to 5 projects", response.body
    assert_match "Up to 50 crew members", response.body
  end

  test "pro plan shows current plan and downgrade path" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_pricing_pro"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_pricing_pro",
      processor_plan: "price_pro_test",
      status: "active"
    )

    sign_in managers(:admin)
    get pricing_path

    assert_response :success
    assert_match "Current Plan", response.body
    assert_match "Downgrade to Starter", response.body
  end
end
