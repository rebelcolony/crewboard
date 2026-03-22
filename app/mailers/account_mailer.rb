class AccountMailer < ApplicationMailer
  def welcome(manager)
    @manager = manager
    @account = manager.account

    mail to: manager.email_address, subject: "Welcome to CrewControl!"
  end

  def confirmation_email(manager)
    @manager = manager
    @account = manager.account
    @verification_url = verify_email_url(token: manager.email_verification_token)

    mail to: manager.email_address, subject: "Verify your CrewControl email"
  end

  def subscription_confirmed(account)
    @account = account
    @manager = account.managers.order(:created_at).first
    @plan = account.plan_name

    mail to: @manager.email_address, subject: "Your #{@plan.capitalize} plan is now active"
  end
end
