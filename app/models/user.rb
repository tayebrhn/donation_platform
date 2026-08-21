class User < ApplicationRecord
  ROLES = %w[donor project_manager admin].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, ROLES.index_by(&:itself), default: "donor", validate: true

  has_many :donations, dependent: :nullify
  has_many :managed_projects,
           class_name: "Project",
           foreign_key: :project_manager_id,
           dependent: :nullify,
           inverse_of: :project_manager

  before_validation :normalize_email

  validates :name, presence: true

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
