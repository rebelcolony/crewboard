require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "invite email is sent with accept link" do
    invite = invites(:pending_invite)
    email = InviteMailer.invite(invite)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ invite.email ], email.to
    assert_match invite.account.name, email.subject
    assert_match "accept", email.body.encoded
    assert_match invite.token, email.body.encoded
    assert_match "7 days", email.body.encoded
  end
end
