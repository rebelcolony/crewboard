require "test_helper"
require "ostruct"

class BillingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in managers(:admin)
  end

  test "unauthenticated user is redirected to login" do
    reset!
    get billing_path
    assert_redirected_to new_session_path
  end

  test "show renders billing page" do
    get billing_path
    assert_response :success
    assert_match "Billing", response.body
    assert_match "Current Plan", response.body
    assert_match "Payment History", response.body
  end

  test "show displays active subscription" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_billing"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_test_billing",
      processor_plan: "price_pro_test",
      status: "active"
    )

    get billing_path
    assert_response :success
    assert_match "Pro", response.body
    assert_match "Active", response.body
  end

  test "show displays free plan when no subscription" do
    get billing_path
    assert_response :success
    assert_match "Free", response.body
    assert_match "Upgrade", response.body
  end

  test "show displays subscription dates, payment methods, and payment history" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_billing_details"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_test_billing_details",
      processor_plan: "price_starter_test",
      status: "active",
      current_period_start: Time.zone.local(2026, 3, 1),
      current_period_end: Time.zone.local(2026, 4, 1),
      trial_ends_at: Time.zone.local(2026, 3, 15),
      ends_at: Time.zone.local(2026, 4, 1)
    )
    subscription = account.payment_processor.subscriptions.order(created_at: :desc).first

    payment_method = stub(
      data: { "last4" => "4242", "exp_month" => 12, "exp_year" => 2030 },
      default?: true
    )
    charge = stub(
      created_at: Time.zone.local(2026, 3, 2),
      amount: 4900,
      currency: "usd",
      amount_refunded: 0,
      data: { "receipt_url" => "https://example.com/receipt" }
    )
    charges_scope = stub
    charges_scope.stubs(:order).with(created_at: :desc).returns(charges_scope)
    charges_scope.stubs(:limit).with(20).returns([ charge ])
    subscription_scope = stub
    subscription_scope.stubs(:active).returns(subscription_scope)
    subscription_scope.stubs(:order).with(created_at: :desc).returns(subscription_scope)
    subscription_scope.stubs(:first).returns(subscription)

    processor = account.payment_processor
    processor.stubs(:subscriptions).returns(subscription_scope)
    processor.stubs(:payment_methods).returns([ payment_method ])
    processor.stubs(:charges).returns(charges_scope)
    Account.any_instance.stubs(:payment_processor).returns(processor)

    get billing_path

    assert_response :success
    assert_match "Mar 01, 2026", response.body
    assert_match "Apr 01, 2026", response.body
    assert_match "Mar 15, 2026", response.body
    assert_match "4242", response.body
    assert_match "12/2030", response.body
    assert_match "Default", response.body
    assert_match "$49.00", response.body
    assert_match "Receipt", response.body
  end

  test "show displays refunded charges" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_billing_refund"

    refunded_charge = stub(
      created_at: Time.zone.local(2026, 3, 5),
      amount: 4900,
      currency: "usd",
      amount_refunded: 4900,
      data: {}
    )
    charges_scope = stub
    charges_scope.stubs(:order).with(created_at: :desc).returns(charges_scope)
    charges_scope.stubs(:limit).with(20).returns([ refunded_charge ])

    processor = account.payment_processor
    processor.stubs(:charges).returns(charges_scope)
    Account.any_instance.stubs(:payment_processor).returns(processor)

    get billing_path

    assert_response :success
    assert_match "Refunded", response.body
  end

  test "portal redirects to Stripe billing portal" do
    fake_portal = OpenStruct.new(url: "https://billing.stripe.com/p/session/test_portal")

    Account.any_instance.stubs(:payment_processor).returns(
      mock("processor").tap { |m|
        m.expects(:billing_portal).with(return_url: billing_url).returns(fake_portal)
      }
    )

    post portal_billing_path
    assert_redirected_to "https://billing.stripe.com/p/session/test_portal"
  end

  test "portal Stripe error redirects to billing with alert" do
    Account.any_instance.stubs(:payment_processor).raises(
      Stripe::AuthenticationError.new("No API key provided")
    )

    post portal_billing_path
    assert_redirected_to billing_path
    assert_match "Billing portal is not available yet", flash[:alert]
  end

  test "portal unexpected error redirects to billing gracefully" do
    Account.any_instance.stubs(:payment_processor).raises(
      RuntimeError.new("unexpected")
    )

    post portal_billing_path
    assert_redirected_to billing_path
    assert_equal "Billing portal is not available yet.", flash[:alert]
  end
end
