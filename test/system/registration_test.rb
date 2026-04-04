require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  test "sign up with new account" do
    visit new_registration_path
    fill_in "Company Name", with: "Test Company Ltd"
    fill_in "Email", with: "signup@example.com"
    fill_in "Password", with: "password123", match: :first
    fill_in "Confirm Password", with: "password123"
    click_on "Create Account"

    assert_current_path verify_email_pending_path
    assert_text "Verify Your Email"
    assert_text "signup@example.com"
    assert_button "Resend Verification Email"
  end

  test "visit verification link signs the user in" do
    account = Account.create!(name: "Verification Company Ltd")
    manager = account.managers.create!(
      email_address: "verify-me@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    manager.generate_email_verification_token!

    visit verify_email_path(token: manager.email_verification_token)

    assert_current_path dashboard_path
    assert_text "Email verified! Welcome to CrewControl!"
    assert_text "Unassigned Crew"
  end
end
