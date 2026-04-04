require "test_helper"
require "ostruct"

class PaymentWebhookHandlersTest < ActiveSupport::TestCase
  test "subscription updated syncs the subscription by processor id" do
    Pay::Stripe::Subscription.expects(:sync).with("sub_updated", stripe_account: nil)

    Pay::Stripe::Webhooks::SubscriptionUpdated.new.call(
      stripe_event("sub_updated")
    )
  end

  test "subscription deleted syncs the canceled subscription by processor id" do
    Pay::Stripe::Subscription.expects(:sync).with("sub_deleted", stripe_account: "acct_123")

    Pay::Stripe::Webhooks::SubscriptionDeleted.new.call(
      stripe_event("sub_deleted", account: "acct_123")
    )
  end

  test "payment failed emails active subscriptions" do
    pay_customer = stub
    pay_subscription = stub(status: "active", customer: pay_customer)
    invoice = OpenStruct.new(subscription: "sub_active")

    Pay::Subscription.stubs(:find_by_processor_and_id).with(:stripe, "sub_active").returns(pay_subscription)
    Pay.stubs(:send_email?).with(:payment_failed, pay_subscription).returns(true)

    mail_delivery = mock("payment_failed_delivery")
    mail_delivery.expects(:deliver_now)
    mailer_scope = mock("payment_failed_scope")
    mailer_scope.expects(:payment_failed).returns(mail_delivery)
    mailer = mock("pay_mailer")
    mailer.expects(:with).with(pay_customer: pay_customer, stripe_invoice: invoice).returns(mailer_scope)
    Pay.stubs(:mailer).returns(mailer)

    Pay::Stripe::Webhooks::PaymentFailed.new.call(
      OpenStruct.new(data: OpenStruct.new(object: invoice))
    )
  end

  test "payment failed skips incomplete subscriptions" do
    pay_subscription = stub(status: "incomplete")

    Pay::Subscription.stubs(:find_by_processor_and_id).with(:stripe, "sub_incomplete").returns(pay_subscription)
    Pay.stubs(:mailer).never

    Pay::Stripe::Webhooks::PaymentFailed.new.call(
      OpenStruct.new(data: OpenStruct.new(object: OpenStruct.new(subscription: "sub_incomplete")))
    )
  end

  test "trial will end syncs and emails active trials" do
    pay_customer = stub
    pay_subscription = mock("trial_subscription")
    pay_subscription.expects(:sync!).with(stripe_account: nil)
    pay_subscription.expects(:customer).returns(pay_customer).at_least_once
    pay_subscription.expects(:on_trial?).returns(true)
    pay_subscription.expects(:trial_ended?).never

    Pay::Subscription.stubs(:find_by_processor_and_id).with(:stripe, "sub_trial").returns(pay_subscription)
    Pay.stubs(:send_email?).with(:subscription_trial_will_end, pay_subscription).returns(true)

    mail_delivery = mock("trial_will_end_delivery")
    mail_delivery.expects(:deliver_later)
    mailer_scope = mock("trial_scope")
    mailer_scope.expects(:subscription_trial_will_end).returns(mail_delivery)
    mailer = mock("pay_mailer")
    mailer.expects(:with).with(pay_customer: pay_customer, pay_subscription: pay_subscription).returns(mailer_scope)
    Pay.stubs(:mailer).returns(mailer)

    Pay::Stripe::Webhooks::SubscriptionTrialWillEnd.new.call(
      stripe_event("sub_trial")
    )
  end

  test "trial will end emails the trial ended notice when the trial has already expired" do
    pay_customer = stub
    pay_subscription = mock("ended_trial_subscription")
    pay_subscription.expects(:sync!).with(stripe_account: "acct_trial")
    pay_subscription.expects(:customer).returns(pay_customer).at_least_once
    pay_subscription.expects(:on_trial?).returns(false)
    pay_subscription.expects(:trial_ended?).returns(true)

    Pay::Subscription.stubs(:find_by_processor_and_id).with(:stripe, "sub_trial_ended").returns(pay_subscription)
    Pay.stubs(:send_email?).with(:subscription_trial_will_end, pay_subscription).returns(true)
    Pay.stubs(:send_email?).with(:subscription_trial_ended, pay_subscription).returns(true)

    mail_delivery = mock("trial_ended_delivery")
    mail_delivery.expects(:deliver_later)
    mailer_scope = mock("trial_ended_scope")
    mailer_scope.expects(:subscription_trial_ended).returns(mail_delivery)
    mailer = mock("pay_mailer")
    mailer.expects(:with).with(pay_customer: pay_customer, pay_subscription: pay_subscription).returns(mailer_scope)
    Pay.stubs(:mailer).returns(mailer)

    Pay::Stripe::Webhooks::SubscriptionTrialWillEnd.new.call(
      stripe_event("sub_trial_ended", account: "acct_trial")
    )
  end

  test "charge refunded syncs the charge and sends a refund email" do
    pay_customer = stub
    pay_charge = stub(customer: pay_customer)

    Pay::Stripe::Charge.stubs(:sync).with("ch_refunded", stripe_account: nil).returns(pay_charge)
    Pay.stubs(:send_email?).with(:refund, pay_charge).returns(true)

    mail_delivery = mock("refund_delivery")
    mail_delivery.expects(:deliver_later)
    mailer_scope = mock("refund_scope")
    mailer_scope.expects(:refund).returns(mail_delivery)
    mailer = mock("pay_mailer")
    mailer.expects(:with).with(pay_customer: pay_customer, pay_charge: pay_charge).returns(mailer_scope)
    Pay.stubs(:mailer).returns(mailer)

    Pay::Stripe::Webhooks::ChargeRefunded.new.call(
      OpenStruct.new(data: OpenStruct.new(object: OpenStruct.new(id: "ch_refunded")))
    )
  end

  test "payment method updated syncs attached customer payment methods" do
    Pay::Stripe::PaymentMethod.expects(:sync).with("pm_123", stripe_account: "acct_pm")

    Pay::Stripe::Webhooks::PaymentMethodUpdated.new.call(
      OpenStruct.new(
        account: "acct_pm",
        data: OpenStruct.new(object: OpenStruct.new(id: "pm_123", customer: "cus_123"))
      )
    )
  end

  test "payment method updated removes detached payment methods" do
    pay_payment_method = mock("pay_payment_method")
    pay_payment_method.expects(:destroy)
    Pay::PaymentMethod.stubs(:find_by_processor_and_id).with(:stripe, "pm_removed").returns(pay_payment_method)

    Pay::Stripe::Webhooks::PaymentMethodUpdated.new.call(
      OpenStruct.new(data: OpenStruct.new(object: OpenStruct.new(id: "pm_removed", customer: nil)))
    )
  end

  private

  def stripe_event(subscription_id, account: nil)
    OpenStruct.new(
      account: account,
      data: OpenStruct.new(object: OpenStruct.new(id: subscription_id))
    )
  end
end
