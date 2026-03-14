class ProfilesController < ApplicationController
  before_action :set_manager

  def show
  end

  def update
    case params[:section]
    when "profile"
      update_profile
    when "password"
      update_password
    when "account"
      update_account
    when "sessions"
      revoke_other_sessions
    else
      redirect_to profile_path
    end
  end

  private

  def set_manager
    @manager = Current.manager
    @account = Current.account
  end

  def update_profile
    if @manager.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    unless @manager.authenticate(params[:current_password])
      @manager.errors.add(:base, "Current password is incorrect")
      @password_error = true
      render :show, status: :unprocessable_entity
      return
    end

    if @manager.update(password_params)
      redirect_to profile_path, notice: "Password updated."
    else
      @password_error = true
      render :show, status: :unprocessable_entity
    end
  end

  def update_account
    if @account.update(account_params)
      redirect_to profile_path, notice: "Account settings updated."
    else
      @account_error = true
      render :show, status: :unprocessable_entity
    end
  end

  def profile_params
    params.require(:manager).permit(:email_address)
  end

  def password_params
    params.require(:manager).permit(:password, :password_confirmation)
  end

  def account_params
    params.require(:account).permit(:name)
  end

  def revoke_other_sessions
    @manager.sessions.where.not(id: Current.session.id).destroy_all
    redirect_to profile_path, notice: "All other sessions have been signed out."
  end
end
