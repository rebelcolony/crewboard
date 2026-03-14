class BillingsController < ApplicationController
  def show
    @account = Current.account
    @subscription = @account.payment_processor&.subscriptions&.active&.order(created_at: :desc)&.first
    @charges = @account.payment_processor&.charges&.order(created_at: :desc)&.limit(20) || []
    @payment_methods = @account.payment_processor&.payment_methods || []
  end

  def portal
    portal_session = Current.account.payment_processor.billing_portal(
      return_url: billing_url
    )
    redirect_to portal_session.url, allow_other_host: true
  rescue Pay::Error, Stripe::StripeError, Stripe::AuthenticationError => e
    redirect_to billing_path, alert: "Billing portal is not available yet. #{e.message}"
  rescue StandardError => e
    redirect_to billing_path, alert: "Billing portal is not available yet."
  end
end
