class CrewMembersController < ApplicationController
  before_action :set_crew_member, only: [ :show, :edit, :update, :destroy ]

  def index
    @crew_members = CrewMember.for_current_account.includes(:project).order(:name)
  end

  def show
  end

  def new
    if Current.account.crew_member_limit_reached?
      redirect_to pricing_path, alert: "You've reached the #{Current.account.crew_member_limit}-member limit on your plan. Upgrade to add more."
      return
    end
    @crew_member = CrewMember.new
  end

  def create
    if Current.account.crew_member_limit_reached?
      redirect_to pricing_path, alert: "You've reached the #{Current.account.crew_member_limit}-member limit on your plan. Upgrade to add more."
      return
    end
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
        format.turbo_stream do
        if request.content_type.include?("application/json")
          render_reassignment
        else
          redirect_to crew_members_path, notice: "Crew member updated."
        end
      end
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
    params.require(:crew_member).permit(:name, :role, :email, :phone, :avatar, :project_id, :status)
  end

  def render_reassignment
    @old_project_id = @crew_member.project_id_before_last_save
    @old_project = Project.find_by(id: @old_project_id)
    @new_project = @crew_member.project
    @projects = Project.for_current_account.includes(:crew_members).order(:name)
    @unassigned_crew = CrewMember.for_current_account.available.where(project_id: nil).order(:name)
    @on_leave_crew = CrewMember.for_current_account.on_leave.order(:name)
  end
end
