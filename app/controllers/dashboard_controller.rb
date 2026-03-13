class DashboardController < ApplicationController
  def show
    @projects = Project.for_current_account.includes(:crew_members).order(:name)
    @unassigned_crew = CrewMember.for_current_account.where(project_id: nil).order(:name)
  end
end
