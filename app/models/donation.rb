class Donation < ApplicationRecord
  STATUSES = %w[pending succeeded failed].freeze
  MINIMUM_AMOUNT_CENTS = 100
  MAXIMUM_AMOUNT_CENTS = 1_000_000

  belongs_to :project

  scope :succeeded, -> { where(status: "succeeded") }

  validates :donor_name, presence: true
  validates :donor_email,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount_cents,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MINIMUM_AMOUNT_CENTS,
              less_than_or_equal_to: MAXIMUM_AMOUNT_CENTS
            }
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  validate :currency_matches_project

  private

  def currency_matches_project
    return if project.nil? || currency == project.currency

    errors.add(:currency, "must match the project currency")
  end
end
