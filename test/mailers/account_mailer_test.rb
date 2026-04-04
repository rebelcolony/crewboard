require "test_helper"

class AccountMailerTest < ActionMailer::TestCase
  test "welcome email is sent to new manager" do
    manager = managers(:admin)
    email = AccountMailer.welcome(manager)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [manager.email_address], email.to
    assert_equal "Welcome to CrewControl!", email.subject
    assert_match manager.account.name, email.body.encoded
    assert_match "Free", email.body.encoded
    assert_match "2 projects", email.body.encoded
  end

  test "subscription confirmed email is sent" do
    account = accounts(:aberdeen)
    # Stub plan_name to test email content
    account.stubs(:plan_name).returns("starter")

    email = AccountMailer.subscription_confirmed(account)

    assert_emails 1 do
      email.deliver_now
    end

    manager = account.managers.order(:created_at).first
    assert_equal [manager.email_address], email.to
    assert_match "Starter", email.subject
    assert_match "Starter", email.body.encoded
    assert_match "5 projects", email.body.encoded
    assert_match "50 crew members", email.body.encoded
  end

  test "subscription confirmed email for pro plan" do
    account = accounts(:aberdeen)
    account.stubs(:plan_name).returns("pro")

    email = AccountMailer.subscription_confirmed(account)

    assert_emails 1 do
      email.deliver_now
    end

    assert_match "Pro", email.subject
    assert_match "unlimited", email.body.encoded
  end

  test "confirmation email includes the verification link" do
    manager = managers(:admin)
    manager.generate_email_verification_token!

    email = AccountMailer.confirmation_email(manager)

    assert_emails 1 do
      email.deliver_now
    end

    html_body = email.html_part.body.decoded

    assert_equal [manager.email_address], email.to
    assert_equal "Verify your CrewControl email", email.subject
    assert_match "http://example.com/verify-email/", html_body
    assert_match manager.email_verification_token, html_body
    assert_match "Verify Email Address", html_body
  end
end
