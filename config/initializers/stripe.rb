stripe_secret_key = ENV["STRIPE_SECRET_KEY"]
stripe_publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"]
stripe_webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"]

if stripe_secret_key.present? && !stripe_secret_key.start_with?("sk_test_")
  raise "STRIPE_SECRET_KEY must be a Stripe test-mode key"
end

if stripe_publishable_key.present? && !stripe_publishable_key.start_with?("pk_test_")
  raise "STRIPE_PUBLISHABLE_KEY must be a Stripe test-mode key"
end

if stripe_webhook_secret.present? && !stripe_webhook_secret.start_with?("whsec_")
  raise "STRIPE_WEBHOOK_SECRET must be a Stripe webhook signing secret"
end

Rails.application.config.x.stripe.secret_key = stripe_secret_key
Rails.application.config.x.stripe.publishable_key = stripe_publishable_key
Rails.application.config.x.stripe.webhook_secret = stripe_webhook_secret
