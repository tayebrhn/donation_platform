module RoleAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def require_role!(*roles)
    return if roles.any? { |role| current_user.public_send("#{role}?") }

    redirect_to root_path, alert: "You are not authorized to access that area."
  end
end
