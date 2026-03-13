module Admin
  class ManagersController < BaseController
    before_action :set_manager, only: [ :show, :edit, :update, :destroy ]

    def index
      @managers = Manager.includes(:account).order(:email_address)
    end

    def show
    end

    def new
      @manager = Manager.new
    end

    def create
      @manager = Manager.new(manager_params)
      if @manager.save
        redirect_to admin_managers_path, notice: "Manager created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      params_to_use = manager_params
      params_to_use = params_to_use.except(:password, :password_confirmation) if params_to_use[:password].blank?
      if @manager.update(params_to_use)
        redirect_to admin_managers_path, notice: "Manager updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @manager.destroy
      redirect_to admin_managers_path, notice: "Manager deleted."
    end

    private

    def set_manager
      @manager = Manager.find(params[:id])
    end

    def manager_params
      params.require(:manager).permit(:email_address, :password, :password_confirmation, :account_id, :super_admin)
    end
  end
end
