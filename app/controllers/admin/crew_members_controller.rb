module Admin
  class CrewMembersController < BaseController
    before_action :set_crew_member, only: [ :show, :edit, :update, :destroy ]

    def index
      @crew_members = CrewMember.includes(:account, :project).order(:name)
    end

    def show
    end

    def new
      @crew_member = CrewMember.new
    end

    def create
      @crew_member = CrewMember.new(crew_member_params)
      if @crew_member.save
        redirect_to admin_crew_members_path, notice: "Crew member created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @crew_member.update(crew_member_params)
        redirect_to admin_crew_members_path, notice: "Crew member updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @crew_member.destroy
      redirect_to admin_crew_members_path, notice: "Crew member deleted."
    end

    private

    def set_crew_member
      @crew_member = CrewMember.find(params[:id])
    end

    def crew_member_params
      params.require(:crew_member).permit(:name, :role, :email, :phone, :project_id, :account_id)
    end
  end
end
