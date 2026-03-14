class PricingController < ApplicationController
  skip_before_action :require_authentication
  before_action :resume_session

  layout "auth"

  def show
    @current_plan = Current.account&.plan_name if authenticated?
  end
end
