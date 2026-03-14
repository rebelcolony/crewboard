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
