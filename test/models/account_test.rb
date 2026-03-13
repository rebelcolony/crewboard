require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid with name" do
    account = Account.new(name: "Test Company")
    assert account.valid?
  end

  test "invalid without name" do
    account = Account.new(name: nil)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "subdomain must be unique when present" do
    assert accounts(:aberdeen).persisted?
    duplicate = Account.new(name: "Another Co", subdomain: "aberdeen")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:subdomain], "has already been taken"
  end

  test "blank subdomain is allowed for multiple accounts" do
    a = Account.create!(name: "No Subdomain A", subdomain: "")
    b = Account.new(name: "No Subdomain B", subdomain: "")
    assert b.valid?
  end

  test "email delegates to first manager" do
    account = accounts(:aberdeen)
    assert_equal managers(:admin).email_address, account.email
  end

  test "email returns nil when no managers" do
    account = Account.create!(name: "Empty Co")
    assert_nil account.email
  end

  test "has many managers" do
    account = accounts(:aberdeen)
    assert_includes account.managers, managers(:admin)
    assert_includes account.managers, managers(:regular)
  end

  test "has many projects" do
    account = accounts(:aberdeen)
    assert_includes account.projects, projects(:forties)
  end

  test "has many crew members" do
    account = accounts(:aberdeen)
    assert_includes account.crew_members, crew_members(:callum)
  end
end
