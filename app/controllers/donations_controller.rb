class DonationsController < ApplicationController
  def new
    @project = Project.where(status: "active").find(params[:project_id])
    @donation = @project.donations.build(currency: @project.currency, status: "pending")
  end
end
