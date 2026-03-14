require "test_helper"

class InviteTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:aberdeen)
    @manager = managers(:admin)
  end

  test "valid invite" do
    invite = @account.invites.build(email: "new@example.com", invited_by: @manager)
    assert invite.valid?
  end

  test "requires email" do
    invite = @account.invites.build(email: "", invited_by: @manager)
    assert_not invite.valid?
    assert invite.errors[:email].any?
  end

  test "rejects invalid email format" do
    invite = @account.invites.build(email: "not-an-email", invited_by: @manager)
    assert_not invite.valid?
  end

  test "rejects email of existing member" do
    invite = @account.invites.build(email: @manager.email_address, invited_by: @manager)
    assert_not invite.valid?
    assert_match "already a member", invite.errors[:email].first
  end

  test "rejects duplicate pending invite" do
    invite = @account.invites.build(email: invites(:pending_invite).email, invited_by: @manager)
    assert_not invite.valid?
    assert_match "pending invite", invite.errors[:email].first
  end

  test "allows re-invite after expiry" do
    invite = @account.invites.build(email: invites(:expired_invite).email, invited_by: @manager)
    assert invite.valid?
  end

  test "pending scope excludes accepted and expired" do
    pending = @account.invites.pending
    assert_includes pending, invites(:pending_invite)
    assert_not_includes pending, invites(:accepted_invite)
    assert_not_includes pending, invites(:expired_invite)
  end

  test "expired?" do
    assert invites(:expired_invite).expired?
    assert_not invites(:pending_invite).expired?
  end

  test "accepted?" do
    assert invites(:accepted_invite).accepted?
    assert_not invites(:pending_invite).accepted?
  end

  test "normalizes email to downcase" do
    invite = @account.invites.create!(email: "  UPPER@EXAMPLE.COM  ", invited_by: @manager)
    assert_equal "upper@example.com", invite.email
  end

  test "generates token on create" do
    invite = @account.invites.create!(email: "tokentest@example.com", invited_by: @manager)
    assert invite.token.present?
    assert invite.token.length >= 32
  end
end
