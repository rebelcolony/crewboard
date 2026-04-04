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

  test "invalid invite token redirects to sign in with an alert" do
    visit accept_invite_path(token: "bogus")

    assert_current_path new_session_path
    assert_text "This invite link is invalid or has expired."
  end
end
