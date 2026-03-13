class CheckoutsController < ApplicationController
  PLANS = {
    "starter" => ENV.fetch("STRIPE_STARTER_PRICE_ID", "price_starter_placeholder"),
    "pro" => ENV.fetch("STRIPE_PRO_PRICE_ID", "price_pro_placeholder")
  }.freeze

  def create
    price_id = PLANS[params[:plan]]
    unless price_id
      redirect_to pricing_path, alert: "Invalid plan selected."
      return
    end

    checkout_session = Current.account.payment_processor.checkout(
      mode: "subscription",
      line_items: price_id,
      success_url: root_url,
      cancel_url: pricing_url
    )

    redirect_to checkout_session.url, allow_other_host: true
  rescue Pay::Error, Stripe::StripeError, Stripe::AuthenticationError => e
    redirect_to pricing_path, alert: "Checkout is not available yet. #{e.message}"
  rescue StandardError => e
    redirect_to pricing_path, alert: "Checkout is not available yet."
  end
end
