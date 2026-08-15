class DonationsController < ApplicationController
  class StripeConfigurationError < StandardError; end
  class StripePaymentMismatchError < StandardError; end

  def new
    load_active_project
    build_donation
  end

  def create
    load_active_project
    build_donation

    unless @donation.valid?
      render :new, status: :unprocessable_content
      return
    end

    create_pending_payment

    redirect_to checkout_donation_path(@donation.signed_id(purpose: :checkout, expires_in: 30.minutes))
  rescue StripeConfigurationError => error
    render_payment_error(error.message, :service_unavailable)
  rescue Stripe::StripeError, StripePaymentMismatchError
    render_payment_error("Payment setup is temporarily unavailable. Please try again.", :bad_gateway)
  end

  def checkout
    @donation = find_signed_donation!(:checkout)
    @project = @donation.project
    return redirect_to_result unless @donation.status == "pending"

    payment_intent = stripe_client.v1.payment_intents.retrieve(@donation.stripe_payment_intent_id)
    verify_payment_intent!(payment_intent)
    return redirect_to_project("This payment can no longer be completed. Please start a new donation.") if payment_intent.status == "canceled"

    @client_secret = payment_intent.client_secret
    @publishable_key = stripe_publishable_key
    @result_url = result_donation_url(
      @donation.signed_id(purpose: :result, expires_in: 2.days)
    )
  rescue StripeConfigurationError, Stripe::StripeError, StripePaymentMismatchError
    redirect_to project_path(@project || @donation&.project),
                alert: "Secure checkout is temporarily unavailable. Please try again."
  end

  def result
    @donation = find_signed_donation!(:result)
    @project = @donation.project
  end

  private

  def load_active_project
    @project = Project.where(status: "active").find(params[:project_id])
  end

  def find_signed_donation!(purpose)
    Donation.find_signed(params[:id], purpose: purpose) || raise(ActiveRecord::RecordNotFound)
  end

  def build_donation
    @amount = donation_params[:amount]
    @donation = @project.donations.build(
      donation_params.slice(:donor_name, :donor_email).merge(
        amount_cents: amount_in_cents(@amount),
        currency: @project.currency,
        status: "pending"
      )
    )
  end

  def donation_params
    @donation_params ||= params.fetch(:donation, {}).permit(:donor_name, :donor_email, :amount)
  end

  def amount_in_cents(amount)
    value = amount.to_s.strip
    return unless value.match?(/\A\d+(?:\.\d{1,2})?\z/)

    (BigDecimal(value) * 100).to_i
  end

  def create_pending_payment
    Donation.transaction do
      @donation.save!
      payment_intent = stripe_client.v1.payment_intents.create(
        {
          amount: @donation.amount_cents,
          currency: @donation.currency.downcase,
          receipt_email: @donation.donor_email,
          description: "Donation to #{@project.title}",
          automatic_payment_methods: { enabled: true },
          metadata: {
            donation_id: @donation.id.to_s,
            project_id: @project.id.to_s
          }
        },
        { idempotency_key: "donation-#{@donation.id}" }
      )
      verify_payment_intent!(payment_intent)
      @donation.update!(stripe_payment_intent_id: payment_intent.id)
    end
  end

  def verify_payment_intent!(payment_intent)
    matches_donation = payment_intent.id.present? &&
                       (@donation.stripe_payment_intent_id.nil? ||
                         payment_intent.id == @donation.stripe_payment_intent_id) &&
                       payment_intent.client_secret.present? &&
                       payment_intent.livemode == false &&
                       payment_intent.amount == @donation.amount_cents &&
                       payment_intent.currency == @donation.currency.downcase &&
                       payment_intent.metadata&.[]("donation_id") == @donation.id.to_s

    raise StripePaymentMismatchError unless matches_donation
  end

  def stripe_client
    @stripe_client ||= Stripe::StripeClient.new(stripe_secret_key)
  end

  def stripe_secret_key
    Rails.configuration.x.stripe.secret_key.presence ||
      raise(StripeConfigurationError, "Stripe test payments are not configured.")
  end

  def stripe_publishable_key
    Rails.configuration.x.stripe.publishable_key.presence ||
      raise(StripeConfigurationError, "Stripe test payments are not configured.")
  end

  def render_payment_error(message, status)
    @donation ||= @project.donations.build(currency: @project.currency, status: "pending")
    @donation.errors.add(:base, message)
    render :new, status: status
  end

  def redirect_to_result
    redirect_to result_donation_path(@donation.signed_id(purpose: :result, expires_in: 2.days))
  end

  def redirect_to_project(message)
    redirect_to project_path(@project), alert: message
  end
end
