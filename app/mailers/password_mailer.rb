class PasswordMailer < ApplicationMailer
  def reset(manager)
    @manager = manager
    @token = manager.generate_token_for(:password_reset)

    mail to: manager.email_address, subject: "Reset your CrewBoard password"
  end
end
