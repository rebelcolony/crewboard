require "application_system_test_case"
require "ostruct"

class SubscriptionCheckoutFlowTest < ApplicationSystemTestCase
  setup do
    Rails.application.credentials.stubs(:dig).with(:stripe, :starter_price_id).returns("price_starter_test")
    Rails.application.credentials.stubs(:dig).with(:stripe, :pro_price_id).returns("price_pro_test")
  end

  test "visitor can move from pricing into the signup flow" do
    visit pricing_path

    click_link "Get Started", match: :first

    assert_current_path new_registration_path
    assert_text "Create your account"
  end

  test "free user can start starter checkout from pricing" do
    checkout_params = nil
    processor = build_processor(
      subscription_name: nil,
      checkout_url: billing_url
    ) do |params|
      checkout_params = params
    end
    Account.any_instance.stubs(:payment_processor).returns(processor)

    system_sign_in
    assert_current_path dashboard_path
    visit pricing_path
    assert_button "Subscribe"

    all(:button, "Subscribe").first.click

    assert_current_path billing_path
    assert_equal "subscription", checkout_params[:mode]
    assert_equal "price_starter_test", checkout_params[:line_items]
    assert_equal "starter", checkout_params.dig(:subscription_data, :metadata, :pay_name)
    assert_equal "/dashboard", URI(checkout_params[:success_url]).path
    assert_equal "/pricing", URI(checkout_params[:cancel_url]).path
  end

  test "free user can start pro checkout from pricing" do
    checkout_params = nil
    processor = build_processor(
      subscription_name: nil,
      checkout_url: billing_url
    ) do |params|
      checkout_params = params
    end
    Account.any_instance.stubs(:payment_processor).returns(processor)

    system_sign_in
    assert_current_path dashboard_path
    visit pricing_path

    all(:button, "Subscribe").last.click

    assert_current_path billing_path
    assert_equal "subscription", checkout_params[:mode]
    assert_equal "price_pro_test", checkout_params[:line_items]
    assert_equal "pro", checkout_params.dig(:subscription_data, :metadata, :pay_name)
    assert_equal "/dashboard", URI(checkout_params[:success_url]).path
    assert_equal "/pricing", URI(checkout_params[:cancel_url]).path
  end

  test "starter user can upgrade to pro from pricing with the pro price id" do
    subscribe_account_to!("starter")
    stripe_update_args = nil
    fake_invoice = OpenStruct.new(payment_intent: nil)
    fake_stripe_sub = OpenStruct.new(latest_invoice: fake_invoice)
    ::Stripe::Subscription.stubs(:update).with do |processor_id, attributes, stripe_options|
      stripe_update_args = {
        processor_id: processor_id,
        attributes: attributes,
        stripe_options: stripe_options
      }
      true
    end.returns(fake_stripe_sub)
    Pay::Subscription.any_instance.stubs(:sync!).returns(true)

    system_sign_in
    assert_current_path dashboard_path
    visit pricing_path
    assert_button "Upgrade to Pro"

    click_button "Upgrade to Pro"

    assert_current_path billing_path
    assert_text "Plan changed to Pro."
    assert_text(/pro/i)
    assert_equal "price_pro_test", stripe_update_args[:attributes][:plan]
    assert_equal false, stripe_update_args[:attributes][:cancel_at_period_end]
    assert_equal "always_invoice", stripe_update_args[:attributes][:proration_behavior]
  end

  test "pro user can downgrade to starter from pricing with the starter price id" do
    subscribe_account_to!("pro")
    stripe_update_args = nil
    fake_invoice = OpenStruct.new(payment_intent: nil)
    fake_stripe_sub = OpenStruct.new(latest_invoice: fake_invoice)
    ::Stripe::Subscription.stubs(:update).with do |processor_id, attributes, stripe_options|
      stripe_update_args = {
        processor_id: processor_id,
        attributes: attributes,
        stripe_options: stripe_options
      }
      true
    end.returns(fake_stripe_sub)
    Pay::Subscription.any_instance.stubs(:sync!).returns(true)

    system_sign_in
    assert_current_path dashboard_path
    visit pricing_path
    assert_text "Current Plan"
    assert_button "Downgrade to Starter"

    click_button "Downgrade to Starter"

    assert_current_path billing_path
    assert_text "Plan changed to Starter."
    assert_text(/starter/i)
    assert_equal "price_starter_test", stripe_update_args[:attributes][:plan]
    assert_equal false, stripe_update_args[:attributes][:cancel_at_period_end]
    assert_equal "always_invoice", stripe_update_args[:attributes][:proration_behavior]
  end

  test "subscribed user can open the billing portal with billing as the return path" do
    portal_params = nil
    processor = build_processor(
      subscription_name: "starter",
      portal_url: pricing_url
    ) do |params|
      portal_params = params
    end
    Account.any_instance.stubs(:payment_processor).returns(processor)

    system_sign_in
    assert_current_path dashboard_path
    click_on "Billing"
    assert_button "Manage Billing"
    click_button "Manage Billing"

    assert_current_path pricing_path
    assert_equal "/billing", URI(portal_params[:return_url]).path
  end

  test "free user sees upgrade on billing and no billing portal action" do
    system_sign_in

    click_on "Billing"

    assert_text(/free/i)
    assert_link "Upgrade"
    assert_no_button "Manage Billing"
  end

  test "checkout failure returns the user to pricing with an alert" do
    system_sign_in
    assert_current_path dashboard_path

    processor = build_processor(subscription_name: nil)
    processor.stubs(:checkout).raises(Pay::Error, "Processor unavailable")
    Account.any_instance.stubs(:payment_processor).returns(processor)

    visit pricing_path
    assert_button "Subscribe"

    find("button", text: "Subscribe", match: :first).click

    assert_current_path pricing_path
    assert_text "Checkout is not available yet. Processor unavailable"
  end

  test "upgrade failure returns the user to pricing with an alert" do
    subscribe_account_to!("starter")
    ::Stripe::Subscription.stubs(:update).raises(Stripe::StripeError.new("Card declined"))

    system_sign_in
    assert_current_path dashboard_path
    visit pricing_path
    click_button "Upgrade to Pro"

    assert_current_path pricing_path
    assert_text "Plan change failed"
  end

  test "billing portal failure returns the user to billing with an alert" do
    processor = build_processor(subscription_name: "starter")
    processor.stubs(:billing_portal).raises(Stripe::AuthenticationError.new("No API key provided"))
    Account.any_instance.stubs(:payment_processor).returns(processor)

    system_sign_in
    click_on "Billing"
    click_button "Manage Billing"

    assert_current_path billing_path
    assert_text "Billing portal is not available yet. No API key provided"
  end

  private

  def build_processor(subscription_name:, checkout_url: nil, portal_url: nil, &capture)
    subscription = if subscription_name
      stub(
        name: subscription_name,
        active?: true,
        status: "active",
        current_period_start: nil,
        current_period_end: nil,
        trial_ends_at: nil,
        ends_at: nil
      )
    end

    ordered_subscriptions = subscription ? [ subscription ] : []
    subscriptions = stub
    subscriptions.stubs(:active).returns(subscriptions)
    subscriptions.stubs(:any?).returns(subscription.present?)
    subscriptions.stubs(:order).with(created_at: :desc).returns(ordered_subscriptions)

    processor = mock("payment_processor")
    processor.stubs(:subscriptions).returns(subscriptions)
    processor.stubs(:charges).returns(stub(order: stub(limit: [])))
    processor.stubs(:payment_methods).returns([])

    if checkout_url
      processor.stubs(:checkout).with do |params|
        capture&.call(params)
        true
      end.returns(OpenStruct.new(url: checkout_url))
    end

    if portal_url
      processor.stubs(:billing_portal).with do |params|
        capture&.call(params)
        true
      end.returns(OpenStruct.new(url: portal_url))
    end

    processor
  end
end
