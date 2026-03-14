require "test_helper"

class Admin::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in managers(:admin)
    # Create a Pay customer + subscription for testing using Pay's API
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_admin_test"
    @subscription = account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_admin_test",
      processor_plan: "price_starter_test",
      status: "active"
    )
  end

  test "super admin can list subscriptions" do
    get admin_subscriptions_path
    assert_response :success
    assert_match "starter", response.body
  end

  test "super admin can view subscription detail" do
    get admin_subscription_path(@subscription)
    assert_response :success
  end

  test "regular manager cannot access subscriptions" do
    reset!
    sign_in managers(:regular)
    get admin_subscriptions_path
    assert_redirected_to root_path
  end

  test "unauthenticated user is redirected to login" do
    reset!
    get admin_subscriptions_path
    assert_redirected_to new_session_path
  end
end
