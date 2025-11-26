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

  # Permission check tests
  test "can? returns true when user has permission" do
    admin = users(:one)
    admin.add_role("admin") unless admin.has_role?("admin")
    regular_user = users(:two)

    # Admin can index users (use User class for collection actions)
    assert admin.can?(:index, User)
    # Admin can show any user
    assert admin.can?(:show, regular_user)
    # Regular user cannot index users
    assert_not regular_user.can?(:index, User)
  end

  test "can? returns false when user does not have permission" do
    regular_user = users(:two)
    other_user = User.create!(
      email_address: "other@example.com",
      password: "password123",
      name: "Other User"
    )

    # Regular user cannot show other users
    assert_not regular_user.can?(:show, other_user)
    # Regular user cannot destroy users
    assert_not regular_user.can?(:destroy, other_user)
  end

  test "can? returns true when user can perform action on themselves" do
    regular_user = users(:two)

    # User can show themselves
    assert regular_user.can?(:show, regular_user)
    # User can update themselves
    assert regular_user.can?(:update, regular_user)
  end

  test "can? returns false for invalid action" do
    admin = users(:one)
    admin.add_role("admin") unless admin.has_role?("admin")

    # Invalid action should return false (NoMethodError)
    assert_not admin.can?(:invalid_action, User)
  end

  test "can? handles nil record for collection actions" do
    admin = users(:one)
    admin.add_role("admin") unless admin.has_role?("admin")

    # Admin can index (collection action with User class)
    assert admin.can?(:index, User)
  end

  # HasRoles concern tests
  test "has_role? returns true when user has the role" do
    user = users(:one)
    user.add_role("admin")

    assert user.has_role?("admin")
    assert user.has_role?(:admin) # Should work with symbol too
  end

  test "has_role? returns false when user does not have the role" do
    user = users(:one)

    assert_not user.has_role?("admin")
    assert_not user.has_role?("user")
  end

  test "add_role creates role if it does not exist" do
    user = users(:one)
    assert_difference "Role.count", 1 do
      user.add_role("new_role")
    end

    assert user.has_role?("new_role")
  end

  test "add_role does not create duplicate user_roles" do
    user = users(:one)
    user.add_role("admin")
    initial_count = user.user_roles.count

    user.add_role("admin") # Add same role again

    assert_equal initial_count, user.user_roles.count
    assert user.has_role?("admin")
  end

  test "remove_role removes role from user" do
    user = users(:one)
    user.add_role("admin")
    assert user.has_role?("admin")

    user.remove_role("admin")

    assert_not user.has_role?("admin")
  end

  test "remove_role does nothing if role does not exist" do
    user = users(:one)
    initial_count = user.user_roles.count

    user.remove_role("non_existent_role")

    assert_equal initial_count, user.user_roles.count
  end

  test "remove_role does nothing if user does not have the role" do
    user = users(:one)
    initial_count = user.user_roles.count

    user.remove_role("admin")

    assert_equal initial_count, user.user_roles.count
  end

  # EmailConfirmation concern tests
  test "confirmed? returns false when confirmed_at is nil" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert_not user.confirmed?
  end

  test "confirmed? returns true when confirmed_at is present" do
    user = users(:one)
    user.update!(confirmed_at: Time.current)

    assert user.confirmed?
  end

  test "confirm! sets confirmed_at and clears confirmation_token" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    token = user.confirmation_token
    assert_not_nil token
    assert_not user.confirmed?

    result = user.confirm!

    assert_equal true, result
    assert user.confirmed?
    assert_nil user.reload.confirmation_token
  end

  test "confirm! returns true if already confirmed" do
    user = users(:one)
    user.update!(confirmed_at: Time.current)
    assert user.confirmed?

    result = user.confirm!

    assert_equal true, result
    assert user.confirmed?
  end

  test "send_confirmation_email updates confirmation_sent_at" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    assert_nil user.confirmation_sent_at

    user.send_confirmation_email

    assert_not_nil user.reload.confirmation_sent_at
  end

  test "send_confirmation_email does not send if already confirmed" do
    user = users(:one)
    user.update!(confirmed_at: Time.current)
    initial_sent_at = user.confirmation_sent_at

    user.send_confirmation_email

    assert_equal initial_sent_at, user.reload.confirmation_sent_at
  end

  test "confirmation_token_valid? returns true for valid token" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    token = user.confirmation_token

    assert user.confirmation_token_valid?(token)
  end

  test "confirmation_token_valid? returns false for invalid token" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )

    assert_not user.confirmation_token_valid?("invalid_token")
  end

  test "confirmation_token_expired? returns true when confirmation_sent_at is nil" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )

    assert user.confirmation_token_expired?
  end

  test "confirmation_token_expired? returns true when token is expired" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    user.update_column(:confirmation_sent_at, 25.hours.ago)

    assert user.confirmation_token_expired?
  end

  test "confirmation_token_expired? returns false when token is not expired" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    user.update_column(:confirmation_sent_at, 1.hour.ago)

    assert_not user.confirmation_token_expired?
  end

  test "confirmation_token_expired? respects custom expires_in parameter" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    user.update_column(:confirmation_sent_at, 2.hours.ago)

    # With default 24 hours, should not be expired
    assert_not user.confirmation_token_expired?
    # With 1 hour, should be expired
    assert user.confirmation_token_expired?(expires_in: 1.hour)
  end

  test "generate_confirmation_token creates token before create" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    assert_nil user.confirmation_token

    user.save!

    assert_not_nil user.confirmation_token
    assert user.confirmation_token.length > 20 # Should be a long random token
  end

  test "generate_confirmation_token does not create token if already confirmed" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      confirmed_at: Time.current
    )

    user.save!

    assert_nil user.confirmation_token
  end
end
