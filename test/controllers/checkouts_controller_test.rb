require "test_helper"
require "ostruct"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in managers(:admin)
    # Ensure credentials return test price IDs
    Rails.application.credentials.stubs(:dig).with(:stripe, :starter_price_id).returns("price_starter_test")
    Rails.application.credentials.stubs(:dig).with(:stripe, :pro_price_id).returns("price_pro_test")
  end

  test "unauthenticated user is redirected to login" do
    reset!  # clear session
    post checkouts_path, params: { plan: "starter" }
    assert_redirected_to new_session_path
  end

  test "invalid plan redirects to pricing with alert" do
    post checkouts_path, params: { plan: "bogus" }
    assert_redirected_to pricing_path
    assert_equal "Invalid plan selected.", flash[:alert]
  end

  test "missing plan param redirects to pricing with alert" do
    post checkouts_path, params: {}
    assert_redirected_to pricing_path
    assert_equal "Invalid plan selected.", flash[:alert]
  end

  test "starter plan creates checkout session and redirects to Stripe" do
    fake_session = OpenStruct.new(url: "https://checkout.stripe.com/pay/cs_test_starter")
    processor = mock("processor")
    processor.expects(:checkout).with(
      mode: "subscription",
      line_items: "price_starter_test",
      success_url: dashboard_url,
      cancel_url: pricing_url,
      subscription_data: { metadata: { pay_name: "starter" } }
    ).returns(fake_session)

    Account.any_instance.stubs(:payment_processor).returns(processor)

    post checkouts_path, params: { plan: "starter" }
    assert_redirected_to "https://checkout.stripe.com/pay/cs_test_starter"
  end

  test "pro plan creates checkout session and redirects to Stripe" do
    fake_session = OpenStruct.new(url: "https://checkout.stripe.com/pay/cs_test_pro")
    processor = mock("processor")
    processor.expects(:checkout).with(
      mode: "subscription",
      line_items: "price_pro_test",
      success_url: dashboard_url,
      cancel_url: pricing_url,
      subscription_data: { metadata: { pay_name: "pro" } }
    ).returns(fake_session)

    Account.any_instance.stubs(:payment_processor).returns(processor)

    post checkouts_path, params: { plan: "pro" }
    assert_redirected_to "https://checkout.stripe.com/pay/cs_test_pro"
  end

  test "Stripe error redirects to pricing with message" do
    Account.any_instance.stubs(:payment_processor).raises(
      Stripe::AuthenticationError.new("No API key provided")
    )

    post checkouts_path, params: { plan: "starter" }
    assert_redirected_to pricing_path
    assert_match "Checkout is not available yet", flash[:alert]
  end

  test "Pay error redirects to pricing with message" do
    Account.any_instance.stubs(:payment_processor).raises(
      Pay::Error.new("Something went wrong")
    )

    post checkouts_path, params: { plan: "starter" }
    assert_redirected_to pricing_path
    assert_match "Checkout is not available yet", flash[:alert]
  end

  test "unexpected error redirects to pricing gracefully" do
    Account.any_instance.stubs(:payment_processor).raises(
      RuntimeError.new("unexpected")
    )

    post checkouts_path, params: { plan: "starter" }
    assert_redirected_to pricing_path
    assert_equal "Checkout is not available yet.", flash[:alert]
  end

  # --- Swap tests ---

  test "swap with invalid plan redirects to pricing" do
    post swap_checkouts_path, params: { plan: "bogus" }
    assert_redirected_to pricing_path
    assert_equal "Invalid plan selected.", flash[:alert]
  end

  test "swap without active subscription redirects to pricing" do
    post swap_checkouts_path, params: { plan: "pro" }
    assert_redirected_to pricing_path
    assert_match "No active subscription", flash[:alert]
  end

  test "swap to same plan redirects to billing with notice" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_swap_same"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_swap_same",
      processor_plan: "price_starter_test",
      status: "active"
    )

    post swap_checkouts_path, params: { plan: "starter" }
    assert_redirected_to billing_path
    assert_match "already on this plan", flash[:notice]
  end

  test "swap changes plan and redirects to billing" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_swap_up"
    sub = account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_swap_up",
      processor_plan: "price_starter_test",
      status: "active"
    )

    # Stub the Stripe API and sync to avoid real API calls
    fake_invoice = OpenStruct.new(payment_intent: nil)
    fake_stripe_sub = OpenStruct.new(latest_invoice: fake_invoice)
    ::Stripe::Subscription.stubs(:update).returns(fake_stripe_sub)
    Pay::Subscription.any_instance.stubs(:sync!).returns(true)

    post swap_checkouts_path, params: { plan: "pro" }
    assert_redirected_to billing_path
    assert_match "Plan changed to Pro", flash[:notice]
    assert_equal "pro", sub.reload.name
  end

  test "swap Stripe error redirects to pricing with message" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_swap_err"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_swap_err",
      processor_plan: "price_starter_test",
      status: "active"
    )

    Pay::Subscription.any_instance.stubs(:swap).raises(
      Stripe::StripeError.new("Card declined")
    )

    post swap_checkouts_path, params: { plan: "pro" }
    assert_redirected_to pricing_path
    assert_match "Plan change failed", flash[:alert]
  end
end
