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

  # --- Billing / plan methods ---

  test "active_subscription? returns false with no payment processor" do
    account = accounts(:aberdeen)
    assert_not account.active_subscription?
  end

  test "active_subscription? returns true with active subscription" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_123"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_test_123",
      processor_plan: "price_starter_test",
      status: "active"
    )
    assert account.reload.active_subscription?
  end

  test "active_subscription? returns false with canceled subscription" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_456"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_test_456",
      processor_plan: "price_starter_test",
      status: "canceled",
      ends_at: 1.day.ago
    )
    assert_not account.reload.active_subscription?
  end

  test "plan_name returns free when no subscription" do
    account = accounts(:aberdeen)
    assert_equal "free", account.plan_name
  end

  test "plan_name returns subscription name when subscription exists" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_789"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_test_789",
      processor_plan: "price_pro_test",
      status: "active"
    )
    assert_equal "pro", account.reload.plan_name
  end

  test "plan_name returns the most recent active subscription name" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_latest"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_test_latest_old",
      processor_plan: "price_starter_test",
      status: "active",
      created_at: 1.day.ago
    )
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_test_latest_new",
      processor_plan: "price_pro_test",
      status: "active"
    )

    assert_equal "pro", account.reload.plan_name
  end

  test "project_limit returns 2 for free plan" do
    account = Account.new(name: "Test")
    assert_equal 2, account.project_limit
  end

  test "project_limit returns 5 for starter plan" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_limit"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_test_limit",
      processor_plan: "price_starter_test",
      status: "active"
    )
    assert_equal 5, account.reload.project_limit
  end

  test "project_limit returns nil (unlimited) for pro plan" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_pro"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_test_pro",
      processor_plan: "price_pro_test",
      status: "active"
    )
    assert_nil account.reload.project_limit
  end

  test "project_limit_reached? is true when at free-tier limit" do
    account = accounts(:aberdeen)
    # aberdeen fixture has 2 projects (forties + brent), free tier limit is 2
    assert account.project_limit_reached?
  end

  test "project_limit_reached? is false when under limit" do
    account = accounts(:aberdeen)
    projects(:brent).destroy
    assert_not account.project_limit_reached?
  end

  test "project_limit_reached? is false for pro plan (unlimited)" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_test_unlim"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_test_unlim",
      processor_plan: "price_pro_test",
      status: "active"
    )
    assert_not account.reload.project_limit_reached?
  end

  # --- Crew member limits ---

  test "crew_member_limit returns 20 for free plan" do
    account = Account.new(name: "Test")
    assert_equal 20, account.crew_member_limit
  end

  test "crew_member_limit returns 50 for starter plan" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_crew_starter"
    account.payment_processor.subscriptions.create!(
      name: "starter",
      processor_id: "sub_crew_starter",
      processor_plan: "price_starter_test",
      status: "active"
    )
    assert_equal 50, account.reload.crew_member_limit
  end

  test "crew_member_limit returns nil (unlimited) for pro plan" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_crew_pro"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_crew_pro",
      processor_plan: "price_pro_test",
      status: "active"
    )
    assert_nil account.reload.crew_member_limit
  end

  test "crew_member_limit_reached? is true when at free-tier limit" do
    account = accounts(:aberdeen)
    remaining_slots = account.crew_member_limit - account.crew_members.count
    remaining_slots.times { |i| account.crew_members.create!(name: "Extra #{i}", role: "Test", email: "extra#{i}@test.com") }
    assert account.crew_member_limit_reached?
  end

  test "crew_member_limit_reached? is false when under limit" do
    account = accounts(:aberdeen)
    assert_not account.crew_member_limit_reached?
  end

  # --- Usage percentages ---

  test "project_usage_percent returns percentage of limit used" do
    account = accounts(:aberdeen)
    # 2 projects, limit 2 = 100%
    assert_equal 100, account.project_usage_percent
  end

  test "project_usage_percent returns 0 for unlimited plan" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_usage_pro"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_usage_pro",
      processor_plan: "price_pro_test",
      status: "active"
    )
    assert_equal 0, account.reload.project_usage_percent
  end

  test "crew_member_usage_percent returns percentage of limit used" do
    account = accounts(:aberdeen)
    assert_equal 10, account.crew_member_usage_percent
  end

  test "crew_member_usage_percent returns 0 for unlimited plan" do
    account = accounts(:aberdeen)
    account.set_payment_processor :stripe, processor_id: "cus_usage_crew_pro"
    account.payment_processor.subscriptions.create!(
      name: "pro",
      processor_id: "sub_usage_crew_pro",
      processor_plan: "price_pro_test",
      status: "active"
    )

    assert_equal 0, account.reload.crew_member_usage_percent
  end
end
