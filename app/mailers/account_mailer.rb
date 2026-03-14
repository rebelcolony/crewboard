class AccountMailer < ApplicationMailer
  def welcome(manager)
    @manager = manager
    @account = manager.account

    mail to: manager.email_address, subject: "Welcome to CrewBoard!"
  end

  def subscription_confirmed(account)
    @account = account
    @manager = account.managers.order(:created_at).first
    @plan = account.plan_name

    mail to: @manager.email_address, subject: "Your #{@plan.capitalize} plan is now active"
  end
end
