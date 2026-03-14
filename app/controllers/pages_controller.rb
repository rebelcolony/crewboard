class PagesController < ApplicationController
  skip_before_action :require_authentication

  layout "marketing"

  def home
    redirect_to dashboard_path if resume_session
  end

  def privacy
  end

  def terms
  end

  def cookies_policy
  end
end
