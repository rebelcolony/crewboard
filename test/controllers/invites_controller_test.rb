require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manager = managers(:admin)
    @account = accounts(:aberdeen)
    sign_in @manager
  end

  # --- Index ---

  test "GET index renders team page" do
    get invites_path
    assert_response :success
    assert_select "h1", /Team/
    assert_select "input[name='invite[email]']"
  end

  test "GET index shows current members" do
    get invites_path
    assert_select "td", @manager.email_address
  end

  test "GET index shows pending invites" do
    get invites_path
    assert_select "td", invites(:pending_invite).email
  end

  test "GET index does not show expired invites" do
    get invites_path
    assert_select "td", { text: invites(:expired_invite).email, count: 0 }
  end

  test "GET index requires authentication" do
    delete session_path
    get invites_path
    assert_redirected_to new_session_path
  end

  # --- Create ---

  test "POST create sends invite email" do
    assert_enqueued_emails 1 do
      post invites_path, params: { invite: { email: "fresh@example.com" } }
    end
    assert_redirected_to invites_path
    assert_match "Invite sent", flash[:notice]
  end

  test "POST create creates invite record" do
    assert_difference "Invite.count", 1 do
      post invites_path, params: { invite: { email: "fresh@example.com" } }
    end
    invite = Invite.last
    assert_equal "fresh@example.com", invite.email
    assert_equal @account, invite.account
    assert_equal @manager, invite.invited_by
  end

  test "POST create rejects duplicate pending invite" do
    post invites_path, params: { invite: { email: invites(:pending_invite).email } }
    assert_response :unprocessable_entity
  end

  test "POST create rejects existing member email" do
    post invites_path, params: { invite: { email: @manager.email_address } }
    assert_response :unprocessable_entity
  end

  test "POST create rejects invalid email" do
    post invites_path, params: { invite: { email: "not-an-email" } }
    assert_response :unprocessable_entity
  end

  # --- Destroy ---

  test "DELETE destroy revokes pending invite" do
    invite = invites(:pending_invite)
    assert_difference "Invite.count", -1 do
      delete invite_path(invite)
    end
    assert_redirected_to invites_path
  end

  # --- Accept (public) ---

  test "GET accept renders accept form for valid token" do
    delete session_path # logout
    invite = invites(:pending_invite)
    get accept_invite_path(token: invite.token)
    assert_response :success
    assert_select "input[name='manager[password]']"
  end

  test "GET accept redirects for invalid token" do
    delete session_path
    get accept_invite_path(token: "bogus")
    assert_redirected_to new_session_path
    assert_match "invalid or has expired", flash[:alert]
  end

  test "GET accept redirects for expired token" do
    delete session_path
    get accept_invite_path(token: invites(:expired_invite).token)
    assert_redirected_to new_session_path
  end

  test "GET accept redirects for already accepted token" do
    delete session_path
    get accept_invite_path(token: invites(:accepted_invite).token)
    assert_redirected_to new_session_path
  end

  # --- Register (public) ---

  test "POST register creates manager and accepts invite" do
    delete session_path
    invite = invites(:pending_invite)

    assert_difference "Manager.count", 1 do
      post accept_invite_path(token: invite.token), params: {
        manager: { password: "securepass1", password_confirmation: "securepass1" }
      }
    end

    assert_redirected_to root_path
    assert invite.reload.accepted?

    new_manager = Manager.find_by(email_address: invite.email)
    assert_equal @account, new_manager.account
    assert new_manager.authenticate("securepass1")
  end

  test "POST register signs in the new manager" do
    delete session_path
    invite = invites(:pending_invite)

    post accept_invite_path(token: invite.token), params: {
      manager: { password: "securepass1", password_confirmation: "securepass1" }
    }

    assert cookies[:session_token].present?
  end

  test "POST register with short password re-renders" do
    delete session_path
    invite = invites(:pending_invite)

    post accept_invite_path(token: invite.token), params: {
      manager: { password: "short", password_confirmation: "short" }
    }
    assert_response :unprocessable_entity
  end

  test "POST register with mismatched password re-renders" do
    delete session_path
    invite = invites(:pending_invite)

    post accept_invite_path(token: invite.token), params: {
      manager: { password: "securepass1", password_confirmation: "different" }
    }
    assert_response :unprocessable_entity
  end

  test "POST register with invalid token redirects" do
    delete session_path
    post accept_invite_path(token: "bogus"), params: {
      manager: { password: "securepass1", password_confirmation: "securepass1" }
    }
    assert_redirected_to new_session_path
  end
end
