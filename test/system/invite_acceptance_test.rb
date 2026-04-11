require "application_system_test_case"

class InviteAcceptanceTest < ApplicationSystemTestCase
  test "invitee can accept an invite and join the team" do
    visit accept_invite_path(token: invites(:pending_invite).token)

    assert_text "Join Aberdeen Offshore Inspections"
    fill_in "Password", with: "securepass1"
    fill_in "Confirm Password", with: "securepass1"
    click_button "Join Team"

    assert_current_path dashboard_path
    assert_text "Projects"
    assert_text "Unassigned Crew"
  end

  test "invitee sees validation feedback when the password is too short" do
    invite = invites(:pending_invite)

    visit accept_invite_path(token: invite.token)

    fill_in "Password", with: "short"
    fill_in "Confirm Password", with: "short"
    click_button "Join Team"

    assert_current_path accept_invite_path(token: invite.token)
    assert_text "Password is too short (minimum is 8 characters)"
    assert_selector "input[type='email'][value='#{invite.email}'][disabled]"
    assert_not invite.reload.accepted?
    assert_nil Manager.find_by(email_address: invite.email)
  end

  test "invalid invite token redirects to sign in with an alert" do
    visit accept_invite_path(token: "bogus")

    assert_current_path new_session_path
    assert_text "This invite link is invalid or has expired."
  end
end
