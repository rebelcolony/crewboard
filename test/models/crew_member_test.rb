require "test_helper"

class CrewMemberTest < ActiveSupport::TestCase
  test "valid with name and account" do
    member = CrewMember.new(name: "Test Person", account: accounts(:aberdeen))
    assert member.valid?
  end

  test "invalid without name" do
    member = CrewMember.new(name: nil, account: accounts(:aberdeen))
    assert_not member.valid?
    assert_includes member.errors[:name], "can't be blank"
  end

  test "initials returns first letters of name" do
    assert_equal "CM", crew_members(:callum).initials
    assert_equal "IC", crew_members(:unassigned_isla).initials
  end

  test "initials handles single name" do
    member = CrewMember.new(name: "Cher")
    assert_equal "C", member.initials
  end

  test "avatar_url returns nil when remote avatars are disabled" do
    assert_nil crew_members(:callum).avatar_url
  end

  test "avatar_url ignores custom size when avatars are disabled" do
    assert_nil crew_members(:callum).avatar_url(size: 150)
  end

  test "assigned? returns true when project present" do
    assert crew_members(:callum).assigned?
  end

  test "assigned? returns false when no project" do
    assert_not crew_members(:unassigned_isla).assigned?
  end

  test "project is optional" do
    member = CrewMember.new(name: "Solo", account: accounts(:aberdeen), project: nil)
    assert member.valid?
  end

  test "belongs to account via tenantable" do
    assert_equal accounts(:aberdeen), crew_members(:callum).account
  end

  test "for_current_account scope filters by tenant" do
    Current.account = accounts(:aberdeen)
    scoped = CrewMember.for_current_account
    assert_includes scoped, crew_members(:callum)
    assert_not_includes scoped, crew_members(:other_crew)
  ensure
    Current.reset
  end
end
