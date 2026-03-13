require "test_helper"

class ManagerTest < ActiveSupport::TestCase
  test "valid with all attributes" do
    manager = Manager.new(
      email_address: "new@example.com",
      password: "password123",
      password_confirmation: "password123",
      account: accounts(:aberdeen)
    )
    assert manager.valid?
  end

  test "invalid without email" do
    manager = Manager.new(
      email_address: nil,
      password: "password123",
      account: accounts(:aberdeen)
    )
    assert_not manager.valid?
    assert_includes manager.errors[:email_address], "can't be blank"
  end

  test "email must be unique" do
    duplicate = Manager.new(
      email_address: "admin@crewboard.com",
      password: "password123",
      account: accounts(:aberdeen)
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "email is normalized to lowercase and stripped" do
    manager = Manager.new(
      email_address: "  ADMIN@Example.COM  ",
      password: "password123",
      account: accounts(:aberdeen)
    )
    assert_equal "admin@example.com", manager.email_address
  end

  test "has_secure_password authenticates correctly" do
    manager = managers(:admin)
    assert manager.authenticate("password123")
    assert_not manager.authenticate("wrongpassword")
  end

  test "super_admin defaults to false" do
    manager = Manager.new
    assert_equal false, manager.super_admin
  end

  test "belongs to account" do
    assert_equal accounts(:aberdeen), managers(:admin).account
  end

  test "has many sessions" do
    manager = managers(:admin)
    assert_includes manager.sessions, sessions(:admin_session)
  end
end
