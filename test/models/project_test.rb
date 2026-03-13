require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid with name and account" do
    project = Project.new(name: "Test Project", account: accounts(:aberdeen))
    assert project.valid?
  end

  test "invalid without name" do
    project = Project.new(name: nil, account: accounts(:aberdeen))
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "progress must be between 0 and 100" do
    project = projects(:forties)

    project.progress = -1
    assert_not project.valid?

    project.progress = 101
    assert_not project.valid?

    project.progress = 50
    assert project.valid?
  end

  test "progress defaults to 0 when nil" do
    project = Project.new(name: "Test", account: accounts(:aberdeen), progress: nil)
    assert_equal 0, project.progress
  end

  test "status enum values" do
    assert_equal "in_progress", projects(:forties).status
    assert_equal "completed", projects(:brent).status
    assert_equal "not_started", projects(:other_project).status
  end

  test "status_color mapping" do
    assert_equal "accent", projects(:forties).status_color
    assert_equal "success", projects(:brent).status_color
  end

  test "belongs to account via tenantable" do
    assert_equal accounts(:aberdeen), projects(:forties).account
  end

  test "has many crew members" do
    assert_includes projects(:forties).crew_members, crew_members(:callum)
  end

  test "for_current_account scope filters by tenant" do
    Current.account = accounts(:aberdeen)
    scoped = Project.for_current_account
    assert_includes scoped, projects(:forties)
    assert_not_includes scoped, projects(:other_project)
  ensure
    Current.reset
  end
end
