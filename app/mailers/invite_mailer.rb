class InviteMailer < ApplicationMailer
  def invite(invite)
    @invite = invite
    @account = invite.account
    @accept_url = accept_invite_url(token: invite.token)

    mail to: invite.email, subject: "You've been invited to #{@account.name} on CrewBoard"
  end
end
