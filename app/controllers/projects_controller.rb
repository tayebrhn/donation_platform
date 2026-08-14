class ProjectsController < ApplicationController
  def index
    @projects = Project.where(status: "active").order(created_at: :desc)
  end

  def show
    @project = Project.where(status: "active").find(params[:id])
  end
end
