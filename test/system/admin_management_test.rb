require "application_system_test_case"

class AdminManagementTest < ApplicationSystemTestCase
  test "super admin can browse admin dashboard and subscription details" do
    subscribe_account_to!("starter")
    system_sign_in

    click_on "Admin"
    assert_text "Admin Dashboard"
    assert_text "Accounts"
    assert_text(/active subscriptions/i)

    click_on "Subscriptions"
    assert_text "starter"
    click_on "View"

    assert_text "Subscription Details"
    assert_text "price_starter_test"
  end

  test "super admin can create and edit an account" do
    system_sign_in

    click_on "Admin"
    click_on "Accounts"
    click_on "New Account"

    fill_in "Name", with: "System Tenant"
    fill_in "Subdomain", with: "system-tenant"
    select "starter", from: "Plan"
    click_button "Create Account"

    assert_text "Account created."
    assert_text "System Tenant"

    click_on "System Tenant"
    click_on "Edit"
    select "pro", from: "Plan"
    click_button "Update Account"

    assert_text "Account updated."
    assert_text "System Tenant"
  end
end
