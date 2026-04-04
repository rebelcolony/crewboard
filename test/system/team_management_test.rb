require "application_system_test_case"

class TeamManagementTest < ApplicationSystemTestCase
  setup do
    system_sign_in
  end

  test "invite a team member from the team page" do
    click_on "Team"
    fill_in "Email Address", with: "teammate@example.com"
    click_on "Send Invite"

    assert_text "Invite sent to teammate@example.com."
    assert_text "teammate@example.com"
  end

  test "revoke a pending invite from the team page" do
    click_on "Team"

    assert_text "newguy@example.com"
    click_on "Revoke", match: :first

    assert_text "Invite revoked."
    assert_no_text "newguy@example.com"
  end

  test "manager can invite a teammate who accepts from the invite link" do
    click_on "Team"
    fill_in "Email Address", with: "journey@example.com"
    click_on "Send Invite"

    assert_text "Invite sent to journey@example.com."

    invite = Invite.find_by!(email: "journey@example.com")

    click_button "Sign Out"
    visit accept_invite_path(token: invite.token)

    assert_text "Join Aberdeen Offshore Inspections"
    fill_in "Password", with: "securepass1"
    fill_in "Confirm Password", with: "securepass1"
    click_button "Join Team"

    assert_current_path dashboard_path

    click_on "Team"
    assert_text "journey@example.com"
  end

  test "update the company name from the profile page" do
    click_on "Profile"
    fill_in "Company Name", with: "Aberdeen Renewables"
    click_on "Update Company"

    assert_text "Account settings updated."
    assert_field "Company Name", with: "Aberdeen Renewables"
  end
end
