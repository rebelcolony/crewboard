class BillingsController < ApplicationController
  def show
    portal_session = Current.account.payment_processor.billing_portal(
      return_url: root_url
    )

    redirect_to portal_session.url, allow_other_host: true
  rescue Pay::Error, Stripe::StripeError, Stripe::AuthenticationError => e
    redirect_to root_path, alert: "Billing portal is not available yet. #{e.message}"
  rescue StandardError => e
    redirect_to root_path, alert: "Billing portal is not available yet."
  end
end
