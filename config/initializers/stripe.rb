Rails.application.config.after_initialize do
  key = Rails.application.credentials.dig(:stripe, :private_key) ||
        Rails.application.credentials.dig(:stripe, :secret_key)
  Stripe.api_key = key if key.present?
end
