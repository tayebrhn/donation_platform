class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @donations = current_user.donations.includes(:project).order(created_at: :desc)
  end

  def edit
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Your profile was updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email)
  end
end
