Rails.application.config.after_initialize do
  key = Rails.application.credentials.dig(:stripe, :private_key) ||
        Rails.application.credentials.dig(:stripe, :secret_key) ||
        ENV["STRIPE_SECRET_KEY"]
  Stripe.api_key = key if key.present?
end
