class PricingController < ApplicationController
  skip_before_action :require_authentication

  layout "auth"

  def show
  end
end
