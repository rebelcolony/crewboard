Rails.application.config.after_initialize do
  if Rails.application.credentials.dig(:stripe, :secret_key).present?
    Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
  end
end
