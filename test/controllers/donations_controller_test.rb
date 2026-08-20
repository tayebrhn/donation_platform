require "test_helper"
require "minitest/mock"

class DonationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:school_library)
    @original_secret_key = Rails.configuration.x.stripe.secret_key
    @original_publishable_key = Rails.configuration.x.stripe.publishable_key
    Rails.configuration.x.stripe.secret_key = "sk_test_example"
    Rails.configuration.x.stripe.publishable_key = "pk_test_example"
  end

  teardown do
    Rails.configuration.x.stripe.secret_key = @original_secret_key
    Rails.configuration.x.stripe.publishable_key = @original_publishable_key
  end

  test "renders the donation form for an active project" do
    get new_project_donation_url(@project)

    assert_response :success
    assert_select "h1", text: /Put your support behind/
    assert_select "form[action=?][method=?]", project_donations_path(@project), "post"
    assert_select "input[name='donation[donor_name]'][required]"
    assert_select "input[name='donation[donor_email]'][required]"
    assert_select "input[name='donation[amount]'][min='1'][max='10000']"
    assert_select "button[type='submit']:not([disabled])", text: /Continue to payment/
  end

  test "does not render a donation form for a draft project" do
    get new_project_donation_url(projects(:community_garden))

    assert_response :not_found
  end

  test "does not create a donation for a missing project" do
    assert_no_difference("Donation.count") do
      post project_donations_url(project_id: 0), params: valid_donation_params
    end

    assert_response :not_found
  end

  test "creates a pending donation and Stripe PaymentIntent" do
    payment_intents = Minitest::Mock.new
    payment_intent = stripe_payment_intent(id: "pi_new_donation", donation_id: nil)
    payment_intents.expect(:create, payment_intent) do |params, options|
      donation = Donation.find_by!(donor_email: "donor@example.com")
      payment_intent.metadata["donation_id"] = donation.id.to_s
      payment_intent.amount = donation.amount_cents

      assert_equal 2_550, params[:amount]
      assert_equal "usd", params[:currency]
      assert_equal "donor@example.com", params[:receipt_email]
      assert_equal({ enabled: true }, params[:automatic_payment_methods])
      assert_equal donation.id.to_s, params[:metadata][:donation_id]
      assert_equal @project.id.to_s, params[:metadata][:project_id]
      assert_equal({ idempotency_key: "donation-#{donation.id}" }, options)
      true
    end

    assert_difference("Donation.count", 1) do
      with_stripe_payment_intents(payment_intents) do
        post project_donations_url(@project), params: valid_donation_params(amount: "25.50")
      end
    end

    donation = Donation.find_by!(donor_email: "donor@example.com")
    assert_response :redirect
    signed_id = URI.parse(response.location).path.delete_prefix("/donations/").delete_suffix("/checkout")
    assert_equal donation, Donation.find_signed(signed_id, purpose: :checkout)
    assert_equal "pending", donation.status
    assert_equal "USD", donation.currency
    assert_equal 2_550, donation.amount_cents
    assert_equal "pi_new_donation", donation.stripe_payment_intent_id
    payment_intents.verify
  end

  test "ignores untrusted project currency status amount cents and PaymentIntent ID" do
    payment_intents = Minitest::Mock.new
    payment_intent = stripe_payment_intent(id: "pi_trusted_fields", donation_id: nil)
    payment_intents.expect(:create, payment_intent) do |params, _options|
      donation = Donation.find_by!(donor_email: "donor@example.com")
      payment_intent.metadata["donation_id"] = donation.id.to_s
      payment_intent.amount = donation.amount_cents
      assert_equal donation.id.to_s, params[:metadata][:donation_id]
      true
    end

    params = valid_donation_params(amount: "10.01")
    params[:donation].merge!(
      amount_cents: 999_999,
      currency: "EUR",
      status: "succeeded",
      stripe_payment_intent_id: "pi_attacker"
    )

    with_stripe_payment_intents(payment_intents) do
      post project_donations_url(@project), params: params
    end

    donation = Donation.find_by!(donor_email: "donor@example.com")
    assert_equal 1_001, donation.amount_cents
    assert_equal "USD", donation.currency
    assert_equal "pending", donation.status
    assert_equal "pi_trusted_fields", donation.stripe_payment_intent_id
  end

  test "rejects malformed or over-precise donation amounts before calling Stripe" do
    [ "10.999", "10 dollars", "-5", "" ].each do |amount|
      assert_no_difference("Donation.count") do
        post project_donations_url(@project), params: valid_donation_params(amount: amount)
      end

      assert_response :unprocessable_content
    end
  end

  test "rejects invalid donor details before calling Stripe" do
    assert_no_difference("Donation.count") do
      post project_donations_url(@project), params: valid_donation_params(donor_email: "invalid")
    end

    assert_response :unprocessable_content
    assert_select ".form-errors", text: /Donor email is invalid/
  end

  test "rolls back the pending donation when Stripe fails" do
    payment_intents = Minitest::Mock.new
    payment_intents.expect(:create, nil) do
      raise Stripe::APIConnectionError, "Stripe unavailable"
    end

    assert_no_difference("Donation.count") do
      with_stripe_payment_intents(payment_intents) do
        post project_donations_url(@project), params: valid_donation_params
      end
    end

    assert_response :bad_gateway
    assert_select ".form-errors", text: /Payment setup is temporarily unavailable/
  end

  test "rolls back the pending donation when Stripe returns a mismatched PaymentIntent" do
    payment_intents = Minitest::Mock.new
    payment_intents.expect(:create, stripe_payment_intent(id: "pi_mismatched", donation_id: "wrong", amount: 2_500)) do |params, options|
      donation = Donation.find_by!(donor_email: "donor@example.com")
      assert_equal 2_500, params[:amount]
      assert_equal({ idempotency_key: "donation-#{donation.id}" }, options)
      true
    end

    assert_no_difference("Donation.count") do
      with_stripe_payment_intents(payment_intents) do
        post project_donations_url(@project), params: valid_donation_params
      end
    end

    assert_response :bad_gateway
    assert_select ".form-errors", text: /Payment setup is temporarily unavailable/
    payment_intents.verify
  end

  test "does not create a donation without Stripe configuration" do
    Rails.configuration.x.stripe.secret_key = nil

    assert_no_difference("Donation.count") do
      post project_donations_url(@project), params: valid_donation_params
    end

    assert_response :service_unavailable
    assert_select ".form-errors", text: /Stripe test payments are not configured/
  end

  test "checkout retrieves and verifies the associated test PaymentIntent" do
    donation = donations(:library_pending)
    payment_intents = Minitest::Mock.new
    payment_intents.expect(
      :retrieve,
      stripe_payment_intent(
        id: donation.stripe_payment_intent_id,
        donation_id: donation.id,
        amount: donation.amount_cents
      ),
      [ donation.stripe_payment_intent_id ]
    )

    with_stripe_payment_intents(payment_intents) do
      get checkout_donation_url(donation.signed_id(purpose: :checkout, expires_in: 30.minutes))
    end

    assert_response :success
    assert_select "[data-controller='stripe-payment']"
    assert_select "[data-stripe-payment-publishable-key-value='pk_test_example']"
    assert_select "[data-stripe-payment-client-secret-value='pi_secret_test']"
    assert_select ".test-mode-label", text: "Test mode"
    assert_select "a[href=?]", project_path(@project), text: "Cancel and return to project"
    payment_intents.verify
  end

  test "checkout rejects a live or mismatched PaymentIntent" do
    donation = donations(:library_pending)
    payment_intents = Minitest::Mock.new
    payment_intents.expect(
      :retrieve,
      stripe_payment_intent(
        id: "pi_different_donation",
        donation_id: donation.id,
        amount: donation.amount_cents
      ),
      [ donation.stripe_payment_intent_id ]
    )

    with_stripe_payment_intents(payment_intents) do
      get checkout_donation_url(donation.signed_id(purpose: :checkout, expires_in: 30.minutes))
    end

    assert_redirected_to project_path(@project)
    assert_equal "Secure checkout is temporarily unavailable. Please try again.", flash[:alert]
  end

  test "does not reopen a terminal donation in checkout" do
    donation = donations(:library_failed)

    get checkout_donation_url(donation.signed_id(purpose: :checkout, expires_in: 30.minutes))

    assert_response :redirect
    signed_id = URI.parse(response.location).path.delete_prefix("/donations/").delete_suffix("/result")
    assert_equal donation, Donation.find_signed(signed_id, purpose: :result)
  end

  test "does not present a canceled PaymentIntent for checkout" do
    donation = donations(:library_pending)
    payment_intents = Minitest::Mock.new
    payment_intents.expect(
      :retrieve,
      stripe_payment_intent(
        id: donation.stripe_payment_intent_id,
        donation_id: donation.id,
        amount: donation.amount_cents,
        status: "canceled"
      ),
      [ donation.stripe_payment_intent_id ]
    )

    with_stripe_payment_intents(payment_intents) do
      get checkout_donation_url(donation.signed_id(purpose: :checkout, expires_in: 30.minutes))
    end

    assert_redirected_to project_path(@project)
    assert_equal "This payment can no longer be completed. Please start a new donation.", flash[:alert]
    payment_intents.verify
  end

  test "handles a Stripe retrieval failure during checkout" do
    donation = donations(:library_pending)
    payment_intents = Minitest::Mock.new
    payment_intents.expect(:retrieve, nil) { raise Stripe::APIConnectionError, "Stripe unavailable" }

    with_stripe_payment_intents(payment_intents) do
      get checkout_donation_url(donation.signed_id(purpose: :checkout, expires_in: 30.minutes))
    end

    assert_redirected_to project_path(@project)
    assert_equal "Secure checkout is temporarily unavailable. Please try again.", flash[:alert]
    payment_intents.verify
  end

  test "handles missing publishable key during checkout" do
    donation = donations(:library_pending)
    Rails.configuration.x.stripe.publishable_key = nil
    payment_intents = Minitest::Mock.new
    payment_intents.expect(
      :retrieve,
      stripe_payment_intent(
        id: donation.stripe_payment_intent_id,
        donation_id: donation.id,
        amount: donation.amount_cents
      ),
      [ donation.stripe_payment_intent_id ]
    )

    with_stripe_payment_intents(payment_intents) do
      get checkout_donation_url(donation.signed_id(purpose: :checkout, expires_in: 30.minutes))
    end

    assert_redirected_to project_path(@project)
    assert_equal "Secure checkout is temporarily unavailable. Please try again.", flash[:alert]
    payment_intents.verify
  end

  test "checkout and result reject unsigned donation IDs" do
    get checkout_donation_url(donations(:library_pending).id)
    assert_response :not_found

    get result_donation_url(donations(:library_pending).id)
    assert_response :not_found
  end

  test "browser return does not mark a pending donation as succeeded" do
    donation = donations(:library_pending)

    get result_donation_url(donation.signed_id(purpose: :result, expires_in: 2.days)),
        params: { payment_intent: donation.stripe_payment_intent_id, redirect_status: "succeeded" }

    assert_response :success
    assert_select "h1", text: "Your payment is being verified."
    assert_equal "pending", donation.reload.status
  end

  test "result explains a failed payment without changing its status" do
    donation = donations(:library_failed)

    get result_donation_url(donation.signed_id(purpose: :result, expires_in: 2.days))

    assert_response :success
    assert_select "h1", text: "Your donation was not charged."
    assert_equal "failed", donation.reload.status
  end

  test "result displays a donation already confirmed by the webhook" do
    donation = donations(:library_first)

    get result_donation_url(donation.signed_id(purpose: :result, expires_in: 2.days))

    assert_response :success
    assert_select "h1", text: "Thank you for helping this project move forward."
    assert_select "body", text: /Stripe has confirmed your \$2,500 donation/
    assert_equal "succeeded", donation.reload.status
  end

  private

  def valid_donation_params(overrides = {})
    {
      donation: {
        donor_name: "Test Donor",
        donor_email: "donor@example.com",
        amount: "25.00"
      }.merge(overrides)
    }
  end

  def stripe_payment_intent(id:, donation_id:, amount: 2_500, livemode: false, status: nil)
    Stripe::PaymentIntent.construct_from(
      id: id,
      client_secret: "pi_secret_test",
      livemode: livemode,
      status: status,
      amount: amount,
      currency: "usd",
      metadata: { donation_id: donation_id&.to_s }
    )
  end

  def with_stripe_payment_intents(payment_intents)
    client = Struct.new(:v1).new(Struct.new(:payment_intents).new(payment_intents))

    Stripe::StripeClient.stub(:new, client) { yield }
  end
end
