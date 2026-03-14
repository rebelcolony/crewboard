require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manager = managers(:admin)
    sign_in @manager
  end

  # --- Show ---

  test "GET show renders profile page" do
    get profile_path
    assert_response :success
    assert_select "h1", "Profile & Settings"
    assert_select "input[name='manager[email_address]']"
  end

  test "GET show requires authentication" do
    delete session_path
    get profile_path
    assert_redirected_to new_session_path
  end

  # --- Update Email ---

  test "PATCH update email successfully" do
    patch profile_path, params: { section: "profile", manager: { email_address: "newemail@example.com" } }
    assert_redirected_to profile_path
    assert_equal "Profile updated.", flash[:notice]
    assert_equal "newemail@example.com", @manager.reload.email_address
  end

  test "PATCH update email with invalid email re-renders" do
    patch profile_path, params: { section: "profile", manager: { email_address: "" } }
    assert_response :unprocessable_entity
  end

  test "PATCH update email with duplicate email re-renders" do
    patch profile_path, params: { section: "profile", manager: { email_address: managers(:other_manager).email_address } }
    assert_response :unprocessable_entity
  end

  # --- Update Password ---

  test "PATCH update password successfully" do
    patch profile_path, params: {
      section: "password",
      current_password: "password123",
      manager: { password: "newsecurepass", password_confirmation: "newsecurepass" }
    }
    assert_redirected_to profile_path
    assert_equal "Password updated.", flash[:notice]
    assert @manager.reload.authenticate("newsecurepass")
  end

  test "PATCH update password with wrong current password fails" do
    patch profile_path, params: {
      section: "password",
      current_password: "wrongpassword",
      manager: { password: "newsecurepass", password_confirmation: "newsecurepass" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update password with too-short password fails" do
    patch profile_path, params: {
      section: "password",
      current_password: "password123",
      manager: { password: "short", password_confirmation: "short" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH update password with mismatched confirmation fails" do
    patch profile_path, params: {
      section: "password",
      current_password: "password123",
      manager: { password: "newsecurepass", password_confirmation: "different" }
    }
    assert_response :unprocessable_entity
  end

  # --- Update Account ---

  test "PATCH update account name successfully" do
    patch profile_path, params: { section: "account", account: { name: "New Company Name" } }
    assert_redirected_to profile_path
    assert_equal "Account settings updated.", flash[:notice]
    assert_equal "New Company Name", @manager.account.reload.name
  end

  test "PATCH update account with blank name fails" do
    patch profile_path, params: { section: "account", account: { name: "" } }
    assert_response :unprocessable_entity
  end

  # --- Sessions ---

  test "PATCH revoke other sessions keeps current session" do
    # Create an extra session for this manager
    extra_session = @manager.sessions.create!(
      ip_address: "1.2.3.4",
      user_agent: "OtherBrowser/1.0"
    )

    patch profile_path, params: { section: "sessions" }
    assert_redirected_to profile_path
    assert_equal "All other sessions have been signed out.", flash[:notice]

    # The extra session should be destroyed
    assert_not Session.exists?(extra_session.id)

    # The current session should still exist (we're still signed in)
    get profile_path
    assert_response :success
  end

  test "shows active sessions table" do
    get profile_path
    assert_select "table" do
      assert_select "th", "IP Address"
      assert_select "th", "Browser"
    end
  end
end
