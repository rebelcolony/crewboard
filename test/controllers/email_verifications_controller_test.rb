require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "GET pending shows the unverified manager email from the session" do
    register_manager(email: "pending@example.com")

    follow_redirect!

    assert_response :success
    assert_match "Verify Your Email", response.body
    assert_match "pending@example.com", response.body
  end

  test "GET pending redirects home when there is no pending verification session" do
    get verify_email_pending_path

    assert_redirected_to root_path
  end

  test "GET verify with a valid token verifies the email and signs the manager in" do
    manager = register_manager(email: "verified@example.com")

    get verify_email_path(token: manager.email_verification_token)

    assert_redirected_to dashboard_path
    assert cookies[:session_token].present?

    manager.reload
    assert manager.email_verified?
    assert_nil manager.email_verification_token
    assert_nil manager.email_verification_token_generated_at
  end

  test "GET verify with an expired token redirects back to pending" do
    manager = register_manager(email: "expired@example.com")
    manager.update_column(:email_verification_token_generated_at, 25.hours.ago)

    get verify_email_path(token: manager.email_verification_token)

    assert_redirected_to verify_email_pending_path
    assert_equal "Verification link has expired. Please request a new one.", flash[:alert]
    assert_not manager.reload.email_verified?
  end

  test "GET verify with an invalid token redirects home" do
    get verify_email_path(token: "not-a-real-token")

    assert_redirected_to root_path
    assert_equal "Invalid verification link.", flash[:alert]
  end

  test "POST resend regenerates the token and sends another verification email" do
    manager = register_manager(email: "resend@example.com")
    original_token = manager.email_verification_token

    travel 1.second do
      assert_enqueued_emails 1 do
        post resend_verification_email_path
      end
    end

    assert_redirected_to verify_email_pending_path
    assert_equal "Verification email sent. Please check your inbox.", flash[:notice]

    manager.reload
    assert_not_equal original_token, manager.email_verification_token
    assert_not_nil manager.email_verification_token_generated_at
  end

  test "POST resend redirects home when the verification session has expired" do
    post resend_verification_email_path

    assert_redirected_to root_path
    assert_equal "Session expired. Please sign up again.", flash[:alert]
  end

  private

  def register_manager(email:)
    post registration_path, params: {
      account: { name: "Verification Co" },
      manager: {
        email_address: email,
        password: "password123",
        password_confirmation: "password123"
      }
    }

    Manager.find_by!(email_address: email)
  end
end
