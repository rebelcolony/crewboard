module Admin
  class SubscriptionsController < BaseController
    def index
      @subscriptions = Pay::Subscription.includes(:customer).order(created_at: :desc)
    end

    def show
      @subscription = Pay::Subscription.find(params[:id])
    end
  end
end
