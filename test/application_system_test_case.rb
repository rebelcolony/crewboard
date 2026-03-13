require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]

  private

  def system_sign_in(email: "admin@crewboard.com", password: "password123")
    visit new_session_path
    fill_in "Email address", with: email
    fill_in "Password", with: password
    click_on "Sign in"
  end
end
