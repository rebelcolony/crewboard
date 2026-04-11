class CheckoutsController < ApplicationController
  def create
    price_id = plans[params[:plan]]
    unless price_id
      redirect_to pricing_path, alert: "Invalid plan selected."
      return
    end

    checkout_session = Current.account.payment_processor.checkout(
      mode: "subscription",
      line_items: price_id,
      success_url: dashboard_url,
      cancel_url: pricing_url,
      subscription_data: { metadata: { pay_name: params[:plan] } }
    )

    redirect_to checkout_session.url, allow_other_host: true
  rescue Pay::Error, Stripe::StripeError, Stripe::AuthenticationError => e
    redirect_to pricing_path, alert: "Checkout is not available yet. #{e.message}"
  rescue StandardError => e
    redirect_to pricing_path, alert: "Checkout is not available yet."
  end

  def swap
    price_id = plans[params[:plan]]
    unless price_id
      redirect_to pricing_path, alert: "Invalid plan selected."
      return
    end

    subscription = Current.account.payment_processor&.subscriptions&.active&.order(created_at: :desc)&.first
    unless subscription
      redirect_to pricing_path, alert: "No active subscription to change."
      return
    end

    if subscription.processor_plan == price_id
      redirect_to billing_path, notice: "You're already on this plan."
      return
    end

    subscription.swap(price_id)
    subscription.update!(name: params[:plan])

    redirect_to billing_path, notice: "Plan changed to #{params[:plan].capitalize}."
  rescue Pay::Error, Stripe::StripeError, Stripe::AuthenticationError => e
    redirect_to pricing_path, alert: "Plan change failed. #{e.message}"
  rescue StandardError => e
    redirect_to pricing_path, alert: "Plan change failed."
  end

  private

  def plans
    {
      "starter" => Rails.application.credentials.dig(:stripe, :starter_price_id) || ENV["STRIPE_STARTER_PRICE_ID"],
      "pro" => Rails.application.credentials.dig(:stripe, :pro_price_id) || ENV["STRIPE_PRO_PRICE_ID"]
    }
  end
end
