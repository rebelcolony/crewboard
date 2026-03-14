require "test_helper"

class Admin::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in managers(:admin)
  end

  test "GET index lists all accounts" do
    get admin_accounts_path
    assert_response :success
    assert_match "Aberdeen Offshore Inspections", response.body
    assert_match "Gulf Coast Inspections", response.body
  end

  test "GET show renders account" do
    get admin_account_path(accounts(:aberdeen))
    assert_response :success
  end

  test "GET new renders form" do
    get new_admin_account_path
    assert_response :success
    assert_select "form"
  end

  test "POST create adds account" do
    assert_difference "Account.count", 1 do
      post admin_accounts_path, params: {
        account: { name: "New Tenant", subdomain: "newtenant", plan: "free" }
      }
    end
    assert_redirected_to admin_accounts_path
  end

  test "PATCH update modifies account" do
    patch admin_account_path(accounts(:aberdeen)), params: {
      account: { plan: "pro" }
    }
    assert_equal "pro", accounts(:aberdeen).reload.plan
  end

  test "DELETE destroy removes account" do
    # Create a standalone account with no FK dependencies
    account = Account.create!(name: "Delete Me")
    assert_difference "Account.count", -1 do
      delete admin_account_path(account)
    end
    assert_redirected_to admin_accounts_path
  end

  test "regular manager cannot access admin accounts" do
    sign_in managers(:regular)
    get admin_accounts_path
    assert_redirected_to root_path
  end
end
