require "test_helper"
require "ostruct"

class PayWebhooksTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
    clear_performed_jobs
    Pay::Stripe::Webhooks::SubscriptionCreated.any_instance.stubs(:call).returns(true)
  end

  test "subscription created webhook sends a confirmation email for account customers" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_webhook_account"

    event = OpenStruct.new(
      data: OpenStruct.new(
        object: OpenStruct.new(customer: "cus_webhook_account")
      )
    )

    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      perform_enqueued_jobs do
        Pay::Webhooks.instrument(type: "stripe.customer.subscription.created", event: event)
      end
    end

    assert_equal [ "admin@crewboard.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "subscription created webhook ignores unknown customers" do
    event = OpenStruct.new(
      data: OpenStruct.new(
        object: OpenStruct.new(customer: "cus_missing")
      )
    )

    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      perform_enqueued_jobs do
        Pay::Webhooks.instrument(type: "stripe.customer.subscription.created", event: event)
      end
    end
  end

  test "subscription created webhook ignores non-account owners" do
    Pay::Customer.stubs(:find_by).returns(stub(owner: managers(:admin)))

    event = OpenStruct.new(
      data: OpenStruct.new(
        object: OpenStruct.new(customer: "cus_manager")
      )
    )

    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      perform_enqueued_jobs do
        Pay::Webhooks.instrument(type: "stripe.customer.subscription.created", event: event)
      end
    end
  end
end
