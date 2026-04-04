require "application_system_test_case"

class PasswordResetFlowTest < ApplicationSystemTestCase
  test "manager can request a password reset and sign in with the new password" do
    perform_enqueued_jobs do
      visit new_password_reset_path
      fill_in "Email", with: managers(:admin).email_address
      click_button "Send Reset Link"
    end

    assert_current_path new_session_path
    assert_text "If that email exists, you'll receive reset instructions shortly."

    token = managers(:admin).generate_token_for(:password_reset)
    visit edit_password_reset_path(token: token)

    fill_in "New Password", with: "freshpassword123"
    fill_in "Confirm Password", with: "freshpassword123"
    click_button "Reset Password"

    assert_current_path new_session_path
    assert_text "Password has been reset. Please sign in."

    system_sign_in(email: managers(:admin).email_address, password: "freshpassword123")
    assert_current_path dashboard_path
  end

  test "invalid reset token redirects back to the reset request form" do
    visit edit_password_reset_path(token: "bogus")

    assert_current_path new_password_reset_path
    assert_text "Invalid or expired reset link. Please request a new one."
  end
end
