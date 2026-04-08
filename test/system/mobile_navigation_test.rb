require "application_system_test_case"

class MobileNavigationTest < ApplicationSystemTestCase
  setup do
    page.current_window.resize_to(390, 844)
  end

  teardown do
    page.current_window.resize_to(1400, 900)
  end

  test "marketing drawer opens and navigates on a phone viewport" do
    visit root_path

    assert_selector ".nav-menu-toggle"
    find(".nav-menu-toggle").click

    within "#marketing-navigation" do
      assert_link "Watch Demo"
      assert_link "Free to Get Started"
      click_link "Sign In"
    end

    assert_current_path new_session_path
  end

  test "authenticated app drawer opens and navigates on a phone viewport" do
    system_sign_in

    assert_selector ".nav-menu-toggle"
    find(".nav-menu-toggle").click

    within "#app-navigation" do
      assert_link "Billing"
      click_link "Billing"
    end

    assert_current_path billing_path
  end
end
