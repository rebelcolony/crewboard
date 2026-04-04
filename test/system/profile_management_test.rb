require "application_system_test_case"

class ProfileManagementTest < ApplicationSystemTestCase
  test "manager can update their email address from profile settings" do
    system_sign_in

    click_on "Profile"
    fill_in "Email", with: "updated-admin@example.com"
    click_on "Update Email"

    assert_text "Profile updated."
    assert_field "Email", with: "updated-admin@example.com"
  end

  test "manager can change password and sign back in with the new password" do
    system_sign_in

    click_on "Profile"
    fill_in "Current Password", with: "password123"
    all("input[name='manager[password]']").first.set("newsecurepass")
    all("input[name='manager[password_confirmation]']").first.set("newsecurepass")
    click_on "Update Password"

    assert_text "Password updated."

    click_on "Sign Out"
    fill_in "Email", with: "admin@crewboard.com"
    fill_in "Password", with: "newsecurepass"
    click_on "Sign In"

    assert_current_path dashboard_path
    assert_text "Unassigned Crew"
  end

  test "manager can sign out all other sessions while staying signed in" do
    manager = managers(:admin)
    manager.sessions.create!(ip_address: "10.0.0.2", user_agent: "Safari/17.0")

    system_sign_in

    click_on "Profile"
    assert_button "Sign Out All Others"

    click_on "Sign Out All Others"

    assert_text "All other sessions have been signed out."
    assert_equal 1, manager.sessions.reload.count
    assert_no_button "Sign Out All Others"
    assert_text "Current"
  end
end
