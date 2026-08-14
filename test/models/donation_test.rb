require "test_helper"

class DonationTest < ActiveSupport::TestCase
  setup do
    @donation = Donation.new(
      project: projects(:community_garden),
      donor_name: "Casey Morgan",
      donor_email: "casey@example.com",
      amount_cents: 2_500,
      currency: "USD",
      status: "pending"
    )
  end

  test "is valid with required attributes" do
    assert_predicate @donation, :valid?
  end

  test "belongs to a project" do
    @donation.project = nil

    assert_predicate @donation, :invalid?
    assert_includes @donation.errors[:project], "must exist"
  end

  test "requires a donor name" do
    @donation.donor_name = nil

    assert_predicate @donation, :invalid?
    assert_includes @donation.errors[:donor_name], "can't be blank"
  end

  test "requires a valid donor email" do
    @donation.donor_email = "not-an-email"

    assert_predicate @donation, :invalid?
    assert_includes @donation.errors[:donor_email], "is invalid"
  end

  test "requires an amount within the allowed range" do
    @donation.amount_cents = Donation::MINIMUM_AMOUNT_CENTS - 1
    assert_predicate @donation, :invalid?

    @donation.amount_cents = Donation::MAXIMUM_AMOUNT_CENTS + 1
    assert_predicate @donation, :invalid?

    @donation.amount_cents = 10.5
    assert_predicate @donation, :invalid?
  end

  test "requires a supported status" do
    @donation.status = "refunded"

    assert_predicate @donation, :invalid?
    assert_includes @donation.errors[:status], "is not included in the list"
  end

  test "requires an uppercase currency matching the project" do
    @donation.currency = "usd"
    assert_predicate @donation, :invalid?

    @donation.currency = "EUR"
    assert_predicate @donation, :invalid?
    assert_includes @donation.errors[:currency], "must match the project currency"
  end

  test "requires a unique Stripe PaymentIntent ID when present" do
    @donation.stripe_payment_intent_id = donations(:library_first).stripe_payment_intent_id

    assert_predicate @donation, :invalid?
    assert_includes @donation.errors[:stripe_payment_intent_id], "has already been taken"
  end

  test "allows multiple donations without Stripe PaymentIntent IDs" do
    first_donation = @donation.dup
    second_donation = @donation.dup

    assert first_donation.save
    assert second_donation.save
  end
end
