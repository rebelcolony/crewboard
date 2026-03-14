class PasswordResetsController < ApplicationController
  skip_before_action :require_authentication
  rate_limit to: 5, within: 1.minute, only: :create, with: -> { redirect_to new_password_reset_path, alert: "Too many requests. Please try again later." }

  layout "auth"

  # GET /password_reset/new — request reset form
  def new
  end

  # POST /password_reset — send reset email
  def create
    if (manager = Manager.find_by(email_address: params[:email_address]))
      PasswordMailer.reset(manager).deliver_later
    end

    redirect_to new_session_path, notice: "If that email exists, you'll receive reset instructions shortly."
  end

  # GET /password_reset/edit?token=xxx — reset form
  def edit
    @manager = Manager.find_by_token_for(:password_reset, params[:token])

    if @manager.nil?
      redirect_to new_password_reset_path, alert: "Invalid or expired reset link. Please request a new one."
    end
  end

  # PATCH /password_reset — update password
  def update
    @manager = Manager.find_by_token_for(:password_reset, params[:token])

    if @manager.nil?
      redirect_to new_password_reset_path, alert: "Invalid or expired reset link. Please request a new one."
      return
    end

    if @manager.update(password_params)
      @manager.sessions.destroy_all
      redirect_to new_session_path, notice: "Password has been reset. Please sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:manager).permit(:password, :password_confirmation)
  end
end
