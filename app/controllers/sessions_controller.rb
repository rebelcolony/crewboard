class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create ]

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
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Invalid email or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
