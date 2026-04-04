require "application_system_test_case"

class BillingFlowTest < ApplicationSystemTestCase
  test "free plan user can move from billing to pricing" do
    system_sign_in

    click_on "Billing"
    assert_text "Current Plan"
    assert_text(/free/i)

    click_on "Upgrade"
    assert_current_path pricing_path
    assert_text "Choose Your Plan"
    assert_text "Up to 5 projects"
    assert_text "Up to 50 crew members"
  end

  test "starter subscriber sees upgrade controls across pricing and billing" do
    subscribe_account_to!("starter")
    system_sign_in

    click_on "Billing"
    assert_text(/starter/i)
    assert_text(/active/i)
  end

  test "billing page shows subscription dates, cards, and payment history" do
    subscribe_account_to!(
      "starter",
      current_period_start: Time.zone.local(2026, 3, 1),
      current_period_end: Time.zone.local(2026, 4, 1),
      trial_ends_at: Time.zone.local(2026, 3, 15),
      ends_at: Time.zone.local(2026, 4, 10)
    )

    payment_method = stub(
      data: { "last4" => "4242", "exp_month" => 12, "exp_year" => 2030 },
      default?: true
    )
    secondary_payment_method = stub(
      data: { "last4" => "1881", "exp_month" => 8, "exp_year" => 2029 },
      default?: false
    )
    paid_charge = stub(
      created_at: Time.zone.local(2026, 3, 2),
      amount: 4900,
      currency: "usd",
      amount_refunded: 0,
      data: { "receipt_url" => "https://example.com/receipt-1" }
    )
    refunded_charge = stub(
      created_at: Time.zone.local(2026, 3, 20),
      amount: 4900,
      currency: "usd",
      amount_refunded: 4900,
      data: {}
    )
    charges_scope = stub
    charges_scope.stubs(:order).with(created_at: :desc).returns(charges_scope)
    charges_scope.stubs(:limit).with(20).returns([ refunded_charge, paid_charge ])

    processor = accounts(:aberdeen).payment_processor
    processor.stubs(:payment_methods).returns([ payment_method, secondary_payment_method ])
    processor.stubs(:charges).returns(charges_scope)
    Account.any_instance.stubs(:payment_processor).returns(processor)

    system_sign_in
    click_on "Billing"

    assert_text "Mar 01, 2026"
    assert_text "Apr 01, 2026"
    assert_text "Mar 15, 2026"
    assert_text "Apr 10, 2026"
    assert_text "4242"
    assert_text "12/2030"
    assert_text "1881"
    assert_text "8/2029"
    assert_text "DEFAULT"
    assert_text "$49.00"
    assert_text "PAID"
    assert_text "REFUNDED"
    assert_link "Receipt", href: "https://example.com/receipt-1"
  end
end
