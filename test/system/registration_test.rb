require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  test "sign up with new account" do
    visit new_registration_path
    fill_in "Company Name", with: "Test Company Ltd"
    fill_in "Email", with: "signup@example.com"
    fill_in "Password", with: "password123", match: :first
    fill_in "Confirm Password", with: "password123"
    click_on "Create Account"

    assert_current_path dashboard_path
    assert_selector ".dashboard"
  end
end
