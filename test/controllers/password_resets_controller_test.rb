require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manager = managers(:admin)
  end

  test "GET new renders forgot password form" do
    get new_password_reset_path
    assert_response :success
    assert_select "input[name=email_address]"
  end

  test "POST create with valid email sends reset email and redirects" do
    assert_enqueued_email_with PasswordMailer, :reset, args: [@manager] do
      post password_reset_path, params: { email_address: @manager.email_address }
    end
    assert_redirected_to new_session_path
    assert_equal "If that email exists, you'll receive reset instructions shortly.", flash[:notice]
  end

  test "POST create with unknown email still redirects with same message" do
    assert_no_enqueued_emails do
      post password_reset_path, params: { email_address: "unknown@example.com" }
    end
    assert_redirected_to new_session_path
    assert_equal "If that email exists, you'll receive reset instructions shortly.", flash[:notice]
  end

  test "GET edit with valid token renders reset form" do
    token = @manager.generate_token_for(:password_reset)
    get edit_password_reset_path(token: token)
    assert_response :success
    assert_select "input[name='manager[password]']"
  end

  test "GET edit with invalid token redirects" do
    get edit_password_reset_path(token: "bogus")
    assert_redirected_to new_password_reset_path
    assert_equal "Invalid or expired reset link. Please request a new one.", flash[:alert]
  end

  test "PATCH update with valid token and password resets password" do
    token = @manager.generate_token_for(:password_reset)
    patch password_reset_path(token: token), params: {
      manager: { password: "newpassword123", password_confirmation: "newpassword123" }
    }
    assert_redirected_to new_session_path
    assert_equal "Password has been reset. Please sign in.", flash[:notice]

    # Verify password changed
    assert @manager.reload.authenticate("newpassword123")
  end

  test "PATCH update invalidates all existing sessions" do
    token = @manager.generate_token_for(:password_reset)
    session_count = @manager.sessions.count
    assert session_count > 0, "fixture should have sessions"

    patch password_reset_path(token: token), params: {
      manager: { password: "newpassword123", password_confirmation: "newpassword123" }
    }
    assert_equal 0, @manager.sessions.reload.count
  end

  test "PATCH update with invalid token redirects" do
    patch password_reset_path(token: "bogus"), params: {
      manager: { password: "newpassword123", password_confirmation: "newpassword123" }
    }
    assert_redirected_to new_password_reset_path
  end

  test "PATCH update with mismatched passwords re-renders form" do
    token = @manager.generate_token_for(:password_reset)
    patch password_reset_path(token: token), params: {
      manager: { password: "newpassword123", password_confirmation: "different" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update with too-short password re-renders form" do
    token = @manager.generate_token_for(:password_reset)
    patch password_reset_path(token: token), params: {
      manager: { password: "short", password_confirmation: "short" }
    }
    assert_response :unprocessable_entity
  end

  test "token is invalidated after password change" do
    token = @manager.generate_token_for(:password_reset)

    # Use the token to reset
    patch password_reset_path(token: token), params: {
      manager: { password: "newpassword123", password_confirmation: "newpassword123" }
    }
    assert_redirected_to new_session_path

    # Try to use the same token again
    get edit_password_reset_path(token: token)
    assert_redirected_to new_password_reset_path
  end
end
