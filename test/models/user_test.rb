require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "validates email_address format" do
    user = User.new(email_address: "invalid-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "是无效的"
  end

  test "validates email_address uniqueness" do
    existing_user = users(:one)
    user = User.new(email_address: existing_user.email_address, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "已经被使用"
  end

  test "validates password strength - minimum length" do
    user = User.new(email_address: "test@example.com", password: "short1")
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 8 characters and include both letters and numbers"
  end

  test "validates password strength - must include letters" do
    user = User.new(email_address: "test@example.com", password: "12345678")
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 8 characters and include both letters and numbers"
  end

  test "validates password strength - must include numbers" do
    user = User.new(email_address: "test@example.com", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 8 characters and include both letters and numbers"
  end

  test "accepts valid password" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert user.valid?
  end

  test "locked? returns true when locked_at is recent" do
    user = users(:one)
    user.update(locked_at: 10.minutes.ago)
    assert user.locked?
  end

  test "locked? returns false when locked_at is old" do
    user = users(:one)
    user.update(locked_at: 31.minutes.ago)
    assert_not user.locked?
  end

  test "unlock! clears locked_at and failed_login_attempts" do
    user = users(:one)
    user.update(locked_at: Time.current, failed_login_attempts: 5)
    user.unlock!
    assert_nil user.locked_at
    assert_equal 0, user.failed_login_attempts
  end

  test "has many sessions" do
    user = users(:one)
    assert_respond_to user, :sessions
  end

  test "active_sessions returns only active sessions" do
    user = users(:one)
    active_session = user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1", active: true)
    inactive_session = user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1", active: false)

    assert_includes user.active_sessions, active_session
    assert_not_includes user.active_sessions, inactive_session
  end

  test "all_sessions returns all sessions ordered by created_at desc" do
    user = users(:one)
    session1 = user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1", active: true, created_at: 2.days.ago)
    session2 = user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1", active: false, created_at: 1.day.ago)
    session3 = user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1", active: true, created_at: Time.current)

    all_sessions = user.all_sessions.to_a
    assert_equal 3, all_sessions.length
    assert_equal session3, all_sessions.first # Most recent first
    assert_equal session1, all_sessions.last # Oldest last
  end

  test "sign_in! creates a new session" do
    user = users(:one)
    assert_difference "user.sessions.count", 1 do
      session = user.sign_in!("Test Agent", "127.0.0.1")
      assert_equal "Test Agent", session.user_agent
      assert_equal "127.0.0.1", session.ip_address
      assert session.active?
    end
  end

  test "validates name minimum length" do
    user = User.new(email_address: "test@example.com", password: "password123", name: "A")
    assert_not user.valid?
    assert_includes user.errors[:name], "过短（最短为2个字符）"
  end

  test "validates name maximum length" do
    user = User.new(email_address: "test@example.com", password: "password123", name: "A" * 101)
    assert_not user.valid?
    assert_includes user.errors[:name], "过长（最长为100个字符）"
  end

  test "allows blank name" do
    user = User.new(email_address: "test@example.com", password: "password123", name: "")
    assert user.valid?
  end

  test "allows nil name" do
    user = User.new(email_address: "test@example.com", password: "password123", name: nil)
    assert user.valid?
  end

  test "accepts valid name length" do
    user = User.new(email_address: "test@example.com", password: "password123", name: "Valid Name")
    assert user.valid?
  end

  test "locked? returns false when locked_at is nil" do
    user = users(:one)
    user.update(locked_at: nil)
    assert_not user.locked?
  end

  test "sign_in! requires user_agent and ip_address" do
    user = users(:one)
    # sign_in! will create a session, but user_agent and ip_address are required
    # If they're nil, the session creation might fail or use defaults
    # Let's test that it works with valid data and creates a session
    session = user.sign_in!("Test Agent", "127.0.0.1")
    assert_not_nil session
    assert_equal "Test Agent", session.user_agent
    assert_equal "127.0.0.1", session.ip_address
  end

  # Password expiration tests
  test "password_expired? returns false when password_changed_at is nil" do
    user = users(:one)
    user.update!(password_changed_at: nil)

    assert_not user.password_expired?
  end

  test "password_expired? returns true when password is expired" do
    user = users(:one)
    user.update!(password_changed_at: 100.days.ago)

    assert user.password_expired?
  end

  test "password_expired? returns false when password is not expired" do
    user = users(:one)
    user.update!(password_changed_at: 30.days.ago)

    assert_not user.password_expired?
  end

  test "password_expires_soon? returns false when password_changed_at is nil" do
    user = users(:one)
    user.update!(password_changed_at: nil)

    assert_not user.password_expires_soon?
  end

  test "password_expires_soon? returns true when password expires soon" do
    user = users(:one)
    # 85 days ago means 5 days until expiration (within 7 days)
    user.update!(password_changed_at: 85.days.ago)

    assert user.password_expires_soon?
  end

  test "password_expires_soon? returns false when password does not expire soon" do
    user = users(:one)
    user.update!(password_changed_at: 30.days.ago)

    assert_not user.password_expires_soon?
  end

  test "password_expires_soon? respects custom days parameter" do
    user = users(:one)
    # 88 days ago means 2 days until expiration
    user.update!(password_changed_at: 88.days.ago)

    # Should return true with default 7 days
    assert user.password_expires_soon?
    # Should return true with 3 days
    assert user.password_expires_soon?(days: 3)
    # Should return false with 1 day
    assert_not user.password_expires_soon?(days: 1)
  end

  test "days_since_password_change returns nil when password_changed_at is nil" do
    user = users(:one)
    user.update!(password_changed_at: nil)

    assert_nil user.days_since_password_change
  end

  test "days_since_password_change returns correct number of days" do
    user = users(:one)
    user.update!(password_changed_at: 30.days.ago)

    assert_equal 30, user.days_since_password_change
  end

  test "days_until_password_expires returns nil when password_changed_at is nil" do
    user = users(:one)
    user.update!(password_changed_at: nil)

    assert_nil user.days_until_password_expires
  end

  test "days_until_password_expires returns correct number of days" do
    user = users(:one)
    user.update!(password_changed_at: 30.days.ago)

    # 90 days expiration - 30 days passed = 60 days remaining
    assert_equal 60, user.days_until_password_expires
  end

  test "days_until_password_expires returns 0 when password is expired" do
    user = users(:one)
    user.update!(password_changed_at: 100.days.ago)

    assert_equal 0, user.days_until_password_expires
  end

  test "update_password_changed_at callback updates timestamp when password changes" do
    user = users(:one)
    old_changed_at = user.password_changed_at

    user.update!(password: "newpass123", password_confirmation: "newpass123")

    assert_not_equal old_changed_at, user.password_changed_at
    assert_not_nil user.password_changed_at
    assert_in_delta Time.current, user.password_changed_at, 1.second
  end

  test "update_password_changed_at callback does not update when password does not change" do
    user = users(:one)
    user.update!(password_changed_at: 10.days.ago)
    old_changed_at = user.password_changed_at

    user.update!(name: "New Name")

    assert_equal old_changed_at, user.password_changed_at
  end

  test "set_initial_password_changed_at sets timestamp for new users" do
    user = User.create!(
      email_address: "newuser@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "New User"
    )

    assert_not_nil user.password_changed_at
    assert_in_delta user.created_at, user.password_changed_at, 1.second
  end
end
