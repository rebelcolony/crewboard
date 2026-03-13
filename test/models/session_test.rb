require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "token is generated on create" do
    session = managers(:admin).sessions.create!(
      ip_address: "192.168.1.1",
      user_agent: "Chrome"
    )
    assert_not_nil session.token
    assert session.token.length >= 32
  end

  test "belongs to manager" do
    assert_equal managers(:admin), sessions(:admin_session).manager
  end
end
