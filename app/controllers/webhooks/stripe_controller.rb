module Webhooks
  class StripeController < ApplicationController
    class StripeConfigurationError < StandardError; end
    class PaymentIntentMismatchError < StandardError; end

    skip_forgery_protection

    PAYMENT_INTENT_EVENTS = {
      "payment_intent.succeeded" => "succeeded",
      "payment_intent.payment_failed" => "failed"
    }.freeze

    def create
      event = Stripe::Webhook.construct_event(request.raw_post, signature, webhook_secret)
      process_event(event)
      head :ok
    rescue Stripe::SignatureVerificationError, JSON::ParserError, ArgumentError
      head :bad_request
    rescue StripeConfigurationError
      head :service_unavailable
    rescue ActiveRecord::RecordNotFound, PaymentIntentMismatchError
      head :unprocessable_content
    end

    private

    def process_event(event)
      status = PAYMENT_INTENT_EVENTS[event.type]
      return unless status

      StripeWebhookEvent.transaction do
        webhook_event = StripeWebhookEvent.create!(
          stripe_event_id: event.id,
          event_type: event.type
        )

        donation = Donation.find_by!(stripe_payment_intent_id: event.data.object.id)
        verify_payment_intent!(donation, event.data.object)
        update_donation_status(donation, status)

        webhook_event.update!(processed_at: Time.current)
      end
    rescue ActiveRecord::RecordNotUnique
      # Stripe may deliver the same event concurrently. The first transaction owns it.
    rescue ActiveRecord::RecordInvalid => error
      raise unless error.record.errors.of_kind?(:stripe_event_id, :taken)
    end

    def update_donation_status(donation, status)
      return if donation.status == "succeeded" && status == "failed"
      return if donation.status == status

      donation.update!(status: status)
    end

    def verify_payment_intent!(donation, payment_intent)
      metadata = payment_intent.metadata
      matches_donation = payment_intent.id == donation.stripe_payment_intent_id &&
                         payment_intent.livemode == false &&
                         payment_intent.amount == donation.amount_cents &&
                         payment_intent.currency == donation.currency.downcase &&
                         metadata&.[]("donation_id") == donation.id.to_s &&
                         metadata&.[]("project_id") == donation.project_id.to_s

      raise PaymentIntentMismatchError unless matches_donation
    end

    def signature
      request.headers["Stripe-Signature"].to_s
    end

    def webhook_secret
      Rails.configuration.x.stripe.webhook_secret.presence ||
        raise(StripeConfigurationError, "Stripe webhook verification is not configured.")
    end
  end
end
