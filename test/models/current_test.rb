require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "session attribute can be set and retrieved" do
    user = users(:one)
    session = user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )

    Current.session = session

    assert_equal session, Current.session
  ensure
    Current.session = nil
  end

  test "session attribute can be nil" do
    Current.session = nil

    assert_nil Current.session
  end

  test "user delegates to session" do
    user = users(:one)
    session = user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )

    Current.session = session

    assert_equal user, Current.user
  ensure
    Current.session = nil
  end

  test "user returns nil when session is nil" do
    Current.session = nil

    assert_nil Current.user
  end

  test "user returns nil when session has no user" do
    # Create a session without a user (shouldn't happen in practice, but test edge case)
    session = Session.new(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    # Don't save, just set it to test delegation
    Current.session = session

    # Should return nil because session.user would be nil
    assert_nil Current.user
  ensure
    Current.session = nil
  end
end
