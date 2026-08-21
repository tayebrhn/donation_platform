class Project < ApplicationRecord
  STATUSES = %w[draft active completed].freeze

  has_many :donations, dependent: :restrict_with_exception
  belongs_to :project_manager,
             class_name: "User",
             optional: true,
             inverse_of: :managed_projects

  validates :title, :description, presence: true
  validates :goal_amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :status, inclusion: { in: STATUSES }
  validate :project_manager_has_management_role

  def amount_raised
    donations.succeeded.sum(:amount_cents)
  end

  def remaining_amount
    [ goal_amount_cents - amount_raised, 0 ].max
  end

  def progress_percentage
    raised = amount_raised
    percentage = (BigDecimal(raised.to_s) / goal_amount_cents * 100).round(1)

    [ percentage, BigDecimal("100.0") ].min
  end

  private

  def project_manager_has_management_role
    return if project_manager.nil? || project_manager.project_manager? || project_manager.admin?

    errors.add(:project_manager, "must have a management role")
  end
end
