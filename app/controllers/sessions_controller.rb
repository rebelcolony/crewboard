class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create ]
  rate_limit to: 10, within: 1.minute, only: :create, with: -> { redirect_to new_session_path, alert: "Too many login attempts. Please try again later." }

  layout "auth"

  def new
  end

  def create
    manager = Manager.authenticate_by(
      email_address: params[:email_address],
      password: params[:password]
    )

    if manager
      start_session(manager)
      redirect_to dashboard_path
    else
      redirect_to new_session_path, alert: "Invalid email or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
