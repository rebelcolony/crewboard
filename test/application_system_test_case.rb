require "test_helper"
require "cgi"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  setup do
    # Session/password-reset rate limit state lives in the cache and can leak
    # across system tests running in one process.
    Rails.cache.clear
  end

  private

  def system_sign_in(email: "admin@crewboard.com", password: "password123")
    visit new_session_path
    within("form.auth-form") do
      fill_in "Email", with: email
      fill_in "Password", with: password
      click_on "Sign In"
    end
  end

  def subscribe_account_to!(plan, account: accounts(:aberdeen), processor_plan: "price_#{plan}_test", **attributes)
    account.set_payment_processor :stripe, processor_id: "cus_#{plan}_#{SecureRandom.hex(4)}"
    account.payment_processor.subscriptions.create!(
      {
        name: plan,
        processor_id: "sub_#{plan}_#{SecureRandom.hex(4)}",
        processor_plan: processor_plan,
        status: "active"
      }.merge(attributes)
    )
  end

  def extract_password_reset_token_from_last_email
    email = ActionMailer::Base.deliveries.last or raise "No delivered email found"
    body = email.html_part&.body&.decoded || email.body.decoded
    token = body[/password_reset\/edit\?token=([^"'&\s<]+)/, 1]
    CGI.unescape(token)
  end
end
