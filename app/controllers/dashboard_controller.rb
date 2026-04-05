class DashboardController < ApplicationController
  def show
    @projects = Project.for_current_account.includes(:crew_members).order(:name)
    @unassigned_crew = CrewMember.for_current_account.available.where(project_id: nil).order(:name)
    @on_leave_crew = CrewMember.for_current_account.on_leave.order(:name)
  end
end
