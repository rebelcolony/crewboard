class RegistrationsController < ApplicationController
  skip_before_action :require_authentication

  layout "auth"

  def new
    @account = Account.new
    @manager = Manager.new
  end

  def create
    @account = Account.new(account_params)
    @manager = @account.managers.build(manager_params)

    ActiveRecord::Base.transaction do
      @account.save!
      @manager.save!
    end

    start_session(@manager)
    AccountMailer.welcome(@manager).deliver_later
    redirect_to dashboard_path, notice: "Welcome to CrewBoard!"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end

  def manager_params
    params.require(:manager).permit(:email_address, :password, :password_confirmation)
  end
end
