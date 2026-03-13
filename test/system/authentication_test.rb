require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "sign in with valid credentials" do
    system_sign_in
    assert_selector "h3", text: /Unassigned Crew/i
    assert_current_path root_path
  end

  test "sign in with bad password shows error" do
    system_sign_in(password: "wrongpassword")
    assert_selector ".alert", text: /invalid/i
    assert_current_path new_session_path
  end

  test "sign out redirects to login" do
    system_sign_in
    click_on "Sign Out"
    assert_selector "h1", text: "CrewBoard"
    assert_selector "input[name=email_address]"
  end
end
