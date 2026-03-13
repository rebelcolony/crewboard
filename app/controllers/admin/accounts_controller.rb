module Admin
  class AccountsController < BaseController
    before_action :set_account, only: [ :show, :edit, :update, :destroy ]

    def index
      @accounts = Account.order(created_at: :desc)
    end

    def show
    end

    def new
      @account = Account.new
    end

    def create
      @account = Account.new(account_params)
      if @account.save
        redirect_to admin_accounts_path, notice: "Account created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @account.update(account_params)
        redirect_to admin_accounts_path, notice: "Account updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @account.destroy
      redirect_to admin_accounts_path, notice: "Account deleted."
    end

    private

    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :subdomain, :plan)
    end
  end
end
