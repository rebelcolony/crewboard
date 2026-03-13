module Admin
  class ProjectsController < BaseController
    before_action :set_project, only: [ :show, :edit, :update, :destroy ]

    def index
      @projects = Project.includes(:account, :crew_members).order(:name)
    end

    def show
    end

    def new
      @project = Project.new
    end

    def create
      @project = Project.new(project_params)
      if @project.save
        redirect_to admin_projects_path, notice: "Project created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @project.update(project_params)
        redirect_to admin_projects_path, notice: "Project updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @project.destroy
      redirect_to admin_projects_path, notice: "Project deleted."
    end

    private

    def set_project
      @project = Project.find(params[:id])
    end

    def project_params
      params.require(:project).permit(:name, :description, :location, :status, :progress, :start_date, :target_end_date, :account_id)
    end
  end
end
