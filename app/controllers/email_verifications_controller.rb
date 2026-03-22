class EmailVerificationsController < ApplicationController
  skip_before_action :require_authentication

  layout "auth"

  def pending
    @manager = Manager.find_by(id: session[:unverified_manager_id])
    redirect_to root_path if @manager.nil? || @manager.email_verified?
  end

  def verify
    token = params[:token]
    manager = Manager.find_by(email_verification_token: token)

    if manager.nil?
      redirect_to root_path, alert: "Invalid verification link."
      return
    end

    if manager.email_verification_token_expired?
      redirect_to verify_email_pending_path, alert: "Verification link has expired. Please request a new one."
      return
    end

    if manager.verify_email_with_token!(token)
      session.delete(:unverified_manager_id)
      start_session(manager)
      redirect_to dashboard_path, notice: "Email verified! Welcome to CrewControl!"
    else
      redirect_to root_path, alert: "Unable to verify email. Please try again."
    end
  end

  def resend
    manager = Manager.find_by(id: session[:unverified_manager_id])

    if manager.nil?
      redirect_to root_path, alert: "Session expired. Please sign up again."
      return
    end

    if manager.email_verified?
      redirect_to dashboard_path
      return
    end

    manager.generate_email_verification_token!
    AccountMailer.confirmation_email(manager).deliver_later
    redirect_to verify_email_pending_path, notice: "Verification email sent. Please check your inbox."
  end
end
