require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  test "sign up with new account" do
    visit new_registration_path
    fill_in "Company name", with: "Test Company Ltd"
    fill_in "Email", with: "signup@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_on "Sign Up"

    assert_current_path root_path
    assert_text "Welcome to CrewBoard!"
  end
end
