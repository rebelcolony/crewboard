require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  setup do
    system_sign_in
  end

  test "project cards are visible on dashboard" do
    assert_selector ".project-card", minimum: 1
    assert_text "Forties Alpha Inspection"
  end

  test "crew avatars are rendered on project cards" do
    assert_selector ".avatar img", minimum: 1
  end

  test "unassigned crew bar is visible" do
    assert_selector ".unassigned-bar"
    assert_text "Unassigned Crew"
  end
end
