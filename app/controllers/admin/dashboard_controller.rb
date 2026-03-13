module Admin
  class DashboardController < BaseController
    def show
      @total_accounts = Account.count
      @total_managers = Manager.count
      @total_projects = Project.count
      @total_crew = CrewMember.count
      @active_subscriptions = Pay::Subscription.where(status: "active").count
      @recent_accounts = Account.order(created_at: :desc).limit(10)
    end
  end
end
