module Manage
  class ProjectsController < BaseController
    before_action :set_project, only: [ :show, :edit, :update, :destroy ]

    def index
      @projects = if current_user.admin?
        Project.order(created_at: :desc)
      else
        current_user.managed_projects.order(created_at: :desc)
      end
    end

    def show
    end

    def new
      @project = Project.new(currency: "USD", status: "draft")
      load_project_managers
    end

    def create
      @project = Project.new(project_params)
      @project.project_manager ||= current_user
      if @project.save
        redirect_to manage_project_path(@project), notice: "Project created."
      else
        load_project_managers
        render :new, status: :unprocessable_content
      end
    end

    def edit
      load_project_managers
    end

    def update
      if @project.update(project_params)
        redirect_to manage_project_path(@project), notice: "Project updated."
      else
        load_project_managers
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @project.destroy
      redirect_to manage_projects_path, notice: "Project removed."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to manage_project_path(@project), alert: "Projects with donations cannot be removed."
    end

    private

    def set_project
      @project = current_user.admin? ? Project.find(params[:id]) : current_user.managed_projects.find(params[:id])
    end

    def project_params
      permitted = [ :title, :description, :goal_amount_cents, :currency, :status ]
      permitted << :project_manager_id if current_user.admin?
      params.require(:project).permit(permitted)
    end

    def load_project_managers
      @project_managers = User.where(role: %w[project_manager admin]).order(:name) if current_user.admin?
    end
  end
end
