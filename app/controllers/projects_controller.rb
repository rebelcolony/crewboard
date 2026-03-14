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
    if Current.account.project_limit_reached?
      redirect_to pricing_path, alert: "You've reached the #{Current.account.project_limit}-project limit on your plan. Upgrade to add more."
      return
    end
    @project = Project.new
  end

  def create
    if Current.account.project_limit_reached?
      redirect_to pricing_path, alert: "You've reached the #{Current.account.project_limit}-project limit on your plan. Upgrade to add more."
      return
    end
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
      respond_to do |format|
        format.turbo_stream {
          @projects = Project.for_current_account.includes(:crew_members).order(:name)
          @unassigned_crew = CrewMember.for_current_account.where(project_id: nil).order(:name)
        }
        format.html { redirect_to projects_path, notice: "Project updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :show, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
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
