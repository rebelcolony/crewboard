class CrewMembersController < ApplicationController
  before_action :set_crew_member, only: [ :show, :edit, :update, :destroy ]

  def index
    @crew_members = CrewMember.for_current_account.includes(:project).order(:name)
  end

  def show
  end

  def new
    @crew_member = CrewMember.new
  end

  def create
    @crew_member = Current.account.crew_members.new(crew_member_params)
    if @crew_member.save
      redirect_to crew_members_path, notice: "Crew member added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @crew_member.update(crew_member_params)
        format.html { redirect_to crew_members_path, notice: "Crew member updated." }
        format.turbo_stream { render_reassignment }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def destroy
    @crew_member.destroy
    redirect_to crew_members_path, notice: "Crew member removed."
  end

  private

  def set_crew_member
    @crew_member = CrewMember.for_current_account.find(params[:id])
  end

  def crew_member_params
    params.require(:crew_member).permit(:name, :role, :email, :phone, :avatar, :project_id)
  end

  def render_reassignment
    @old_project_id = @crew_member.project_id_before_last_save
    @old_project = Project.find_by(id: @old_project_id)
    @new_project = @crew_member.project
    @projects = Project.for_current_account.includes(:crew_members).order(:name)
    @unassigned_crew = CrewMember.for_current_account.where(project_id: nil).order(:name)
  end
end
