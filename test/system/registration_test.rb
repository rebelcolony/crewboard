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

  test "sign up with an invalid password re-renders the form with validation feedback" do
    visit new_registration_path
    fill_in "Company Name", with: "Validation Company Ltd"
    fill_in "Email", with: "invalid-signup@example.com"
    fill_in "Password", with: "short", match: :first
    fill_in "Confirm Password", with: "short"
    click_on "Create Account"

    assert_current_path new_registration_path
    assert_text "Password is too short (minimum is 8 characters)"
    assert_field "Company Name", with: "Validation Company Ltd"
    assert_field "Email", with: "invalid-signup@example.com"
  end

  test "pending verification page can resend the verification email" do
    visit new_registration_path
    fill_in "Company Name", with: "Resend Company Ltd"
    fill_in "Email", with: "resend-signup@example.com"
    fill_in "Password", with: "password123", match: :first
    fill_in "Confirm Password", with: "password123"
    click_on "Create Account"

    assert_current_path verify_email_pending_path
    assert_text "resend-signup@example.com"

    click_button "Resend Verification Email"

    assert_current_path verify_email_pending_path
    assert_text "Verification email sent. Please check your inbox."
    assert_text "resend-signup@example.com"
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
