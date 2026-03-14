module Admin
  class DashboardController < BaseController
    def show
      @total_accounts = Account.count
      @active_subscriptions = Pay::Subscription.where(status: "active").count
      @recent_accounts = Account.order(created_at: :desc).limit(10)
    end
  end
end
