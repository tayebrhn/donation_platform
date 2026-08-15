require "test_helper"

module Webhooks
  class StripeControllerTest < ActionDispatch::IntegrationTest
    WEBHOOK_SECRET = "whsec_test_signing_secret"

    setup do
      @donation = donations(:library_pending)
      @original_webhook_secret = Rails.configuration.x.stripe.webhook_secret
      Rails.configuration.x.stripe.webhook_secret = WEBHOOK_SECRET
    end

    teardown do
      Rails.configuration.x.stripe.webhook_secret = @original_webhook_secret
    end

    test "marks a donation succeeded after a valid signed event" do
      payload = event_payload(event_id: "evt_payment_succeeded", type: "payment_intent.succeeded")

      assert_difference("StripeWebhookEvent.count", 1) do
        post_webhook(payload)
      end

      assert_response :ok
      assert_equal "succeeded", @donation.reload.status
      assert_predicate StripeWebhookEvent.find_by!(stripe_event_id: "evt_payment_succeeded").processed_at, :present?
    end

    test "marks a donation failed after a valid signed event" do
      payload = event_payload(event_id: "evt_payment_failed", type: "payment_intent.payment_failed")

      post_webhook(payload)

      assert_response :ok
      assert_equal "failed", @donation.reload.status
    end

    test "rejects an invalid signature" do
      payload = event_payload(event_id: "evt_invalid_signature", type: "payment_intent.succeeded")

      assert_no_difference("StripeWebhookEvent.count") do
        post_webhook(payload, signature: "t=#{Time.current.to_i},v1=invalid")
      end

      assert_response :bad_request
      assert_equal "pending", @donation.reload.status
    end

    test "rejects a stale signature" do
      payload = event_payload(event_id: "evt_stale_signature", type: "payment_intent.succeeded")

      post_webhook(payload, timestamp: 10.minutes.ago)

      assert_response :bad_request
      assert_equal "pending", @donation.reload.status
    end

    test "processes duplicate event deliveries only once" do
      payload = event_payload(event_id: "evt_duplicate", type: "payment_intent.succeeded")

      assert_difference("StripeWebhookEvent.count", 1) do
        post_webhook(payload)
        assert_response :ok
        post_webhook(payload)
        assert_response :ok
      end

      assert_equal "succeeded", @donation.reload.status
    end

    test "acknowledges unsupported event types without storing them" do
      payload = event_payload(event_id: "evt_charge", type: "charge.succeeded")

      assert_no_difference("StripeWebhookEvent.count") do
        post_webhook(payload)
      end

      assert_response :ok
      assert_equal "pending", @donation.reload.status
    end

    test "rejects a mismatched PaymentIntent snapshot" do
      invalid_snapshots = [
        { amount: @donation.amount_cents + 1 },
        { currency: "eur" },
        { livemode: true },
        { metadata: { donation_id: @donation.id.to_s, project_id: "wrong" } }
      ]

      invalid_snapshots.each_with_index do |overrides, index|
        payload = event_payload(
          event_id: "evt_mismatch_#{index}",
          type: "payment_intent.succeeded",
          intent_overrides: overrides
        )

        assert_no_difference("StripeWebhookEvent.count") { post_webhook(payload) }
        assert_response :unprocessable_content
        assert_equal "pending", @donation.reload.status
      end
    end

    test "rejects an event for an unknown PaymentIntent" do
      payload = event_payload(
        event_id: "evt_unknown_intent",
        type: "payment_intent.succeeded",
        intent_overrides: { id: "pi_unknown" }
      )

      assert_no_difference("StripeWebhookEvent.count") { post_webhook(payload) }

      assert_response :unprocessable_content
      assert_equal "pending", @donation.reload.status
    end

    test "does not let a late failed event regress a succeeded donation" do
      @donation.update!(status: "succeeded")
      payload = event_payload(event_id: "evt_late_failure", type: "payment_intent.payment_failed")

      assert_difference("StripeWebhookEvent.count", 1) { post_webhook(payload) }

      assert_response :ok
      assert_equal "succeeded", @donation.reload.status
    end

    test "returns service unavailable when webhook verification is not configured" do
      Rails.configuration.x.stripe.webhook_secret = nil
      payload = event_payload(event_id: "evt_no_config", type: "payment_intent.succeeded")

      post_webhook(payload)

      assert_response :service_unavailable
      assert_equal "pending", @donation.reload.status
    end

    private

    def event_payload(event_id:, type:, intent_overrides: {})
      payment_intent = {
        id: @donation.stripe_payment_intent_id,
        object: "payment_intent",
        amount: @donation.amount_cents,
        currency: @donation.currency.downcase,
        livemode: false,
        metadata: {
          donation_id: @donation.id.to_s,
          project_id: @donation.project_id.to_s
        }
      }.merge(intent_overrides)

      JSON.generate(
        id: event_id,
        object: "event",
        type: type,
        data: { object: payment_intent }
      )
    end

    def post_webhook(payload, signature: nil, timestamp: Time.current)
      signature ||= signature_for(payload, timestamp)
      post "/webhooks/stripe",
           params: payload,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "Stripe-Signature" => signature
           }
    end

    def signature_for(payload, timestamp)
      signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, WEBHOOK_SECRET)
      Stripe::Webhook::Signature.generate_header(timestamp, signature)
    end
  end
end
