require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  test "reset email is sent with reset link" do
    manager = managers(:admin)
    email = PasswordMailer.reset(manager)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ manager.email_address ], email.to
    assert_equal "Reset your CrewControl password", email.subject
    assert_match "Reset my password", email.body.encoded
    assert_match "password_reset", email.body.encoded
    assert_match "2 hours", email.body.encoded
  end
end
