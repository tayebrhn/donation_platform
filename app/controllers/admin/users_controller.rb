module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :edit, :update ]

    def index
      @users = User.order(created_at: :desc)
    end

    def edit
    end

    def update
      if @user == current_user && requested_role != current_user.role
        @user.errors.add(:role, "cannot be changed for your own account")
        render :edit, status: :unprocessable_content
        return
      end

      @user.role = requested_role
      if @user.save
        redirect_to admin_users_path, notice: "User role updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def requested_role
      params.require(:user).fetch(:role).to_s
    end
  end
end
