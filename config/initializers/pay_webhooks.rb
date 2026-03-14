Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.created" do |event|
  stripe_sub = event.data.object
  pay_customer = Pay::Customer.find_by(processor: :stripe, processor_id: stripe_sub.customer)
  next unless pay_customer

  account = pay_customer.owner
  next unless account.is_a?(Account)

  AccountMailer.subscription_confirmed(account).deliver_later
end
