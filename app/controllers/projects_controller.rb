class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

  def index
    @projects = Project.for_current_account.includes(:crew_members).order(:name)
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @project = Project.new
  end

  def create
    @project = Current.account.projects.new(project_params)
    if @project.save
      redirect_to projects_path, notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to projects_path, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  private

  def set_project
    @project = Project.for_current_account.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :location, :status, :progress, :start_date, :target_end_date)
  end
end
