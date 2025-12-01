require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clear cache to ensure clean state for each test
    # This prevents rate_limit from affecting tests that don't explicitly test it
    Rails.cache.clear

    @user = users(:one)
    # Fixture already has password_digest for "password123", but we need to ensure it's correct
    # Update password to ensure it's properly set (fixture password is already "password123")
    @user.update!(password: "password123", password_confirmation: "password123")
  end

  test "new redirects to root if already authenticated" do
    # Sign in by making actual login request
    sign_in_as(@user)
    # After sign_in_as, we should be authenticated
    # Make another request to verify session persists
    get root_path
    # Now try to access new session path - should redirect
    get new_session_path
    assert_redirected_to root_path
  end

  test "new shows login form if not authenticated" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    # Ensure user is confirmed
    @user.update!(confirmed_at: Time.current) unless @user.confirmed?
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    assert_redirected_to root_path
    # In integration tests, Warden callbacks should set Current.session after authentication
    # Check that a session was created for the user
    user = User.find_by(email_address: @user.email_address)
    assert user.sessions.active.any?, "Session should be created after login"
  end

  test "create with unconfirmed user redirects with error" do
    # Create unconfirmed user
    unconfirmed_user = User.create!(
      email_address: "unconfirmed@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Unconfirmed User"
    )
    assert_not unconfirmed_user.confirmed?, "User should not be confirmed"

    post session_path, params: { email_address: unconfirmed_user.email_address, password: "password123" }

    assert_redirected_to new_session_path
    assert_equal "请先确认您的邮箱地址。我们已向您的邮箱发送了确认链接。", flash[:alert]
    assert_nil Current.user, "User should not be authenticated"
    # Verify no session was created
    assert_equal 0, unconfirmed_user.sessions.active.count, "No session should be created for unconfirmed user"
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrongpassword" }

    assert_redirected_to new_session_path
    assert_nil Current.user
  end

  test "create with remember_me creates remember_token cookie" do
    post session_path, params: {
      email_address: @user.email_address,
      password: "password123",
      remember_me: "1"
    }

    assert_redirected_to root_path
    # Check that session was created and has remember_token
    user = User.find_by(email_address: @user.email_address)
    session = user.sessions.active.order(created_at: :desc).first
    assert session.present?, "Session should be created"
    assert session.remember_token.present?, "Session should have remember_token when remember_me is checked"
  end

  test "create without remember_me does not create remember_token cookie" do
    post session_path, params: {
      email_address: @user.email_address,
      password: "password123",
      remember_me: "0"
    }

    assert_redirected_to root_path
    # Check that session was created but doesn't have remember_token
    user = User.find_by(email_address: @user.email_address)
    session = user.sessions.active.order(created_at: :desc).first
    assert session.present?, "Session should be created"
    assert_nil session.remember_token, "Session should not have remember_token when remember_me is not checked"
  end

  test "destroy terminates session and clears remember_token" do
    sign_in_as(@user)
    # After sign_in_as, get the session that was created
    user = User.find_by(email_address: @user.email_address)
    session = user.sessions.active.order(created_at: :desc).first
    assert session.present?, "Session should be created after sign_in_as"
    session.remember_me!
    session.save! # Ensure remember_token is saved
    session_id = session.id

    # Make a request to ensure session is restored in Warden and Current.session is set
    get root_path
    # Verify session is active before logout
    assert session.reload.active?, "Session should be active before logout"

    delete session_path

    assert_redirected_to new_session_path
    # Check that session was terminated - reload from database
    session = Session.find(session_id)
    assert_not session.active?, "Session should be inactive after logout (active: #{session.active}, id: #{session.id})"
    assert_nil session.remember_token, "Session should not have remember_token after logout"
  end

  test "create with locked account shows error" do
    @user.update!(locked_at: 10.minutes.ago, failed_login_attempts: 0)
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    assert_redirected_to new_session_path
    # Follow redirect to see flash message
    follow_redirect!
    # Check flash message contains "locked"
    assert_match(/locked/i, flash[:alert].to_s) if flash[:alert].present?
    # Also check the response body for locked message
    assert_match(/locked/i, response.body) if response.body.present?
  end

  test "create with non-existent user shows generic error" do
    post session_path, params: { email_address: "nonexistent@example.com", password: "password123" }

    assert_redirected_to new_session_path
    assert_equal "Invalid email address or password.", flash[:alert]
    assert_nil Current.user
  end

  test "create increments failed login attempts" do
    initial_attempts = @user.failed_login_attempts
    post session_path, params: { email_address: @user.email_address, password: "wrongpassword" }

    @user.reload
    assert_equal initial_attempts + 1, @user.failed_login_attempts
  end

  test "create locks account after 5 failed attempts" do
    @user.update!(failed_login_attempts: 4)

    post session_path, params: { email_address: @user.email_address, password: "wrongpassword" }

    @user.reload
    assert_equal 5, @user.failed_login_attempts
    assert_not_nil @user.locked_at
    assert_redirected_to new_session_path
    follow_redirect!
    assert_match(/locked/i, flash[:alert].to_s)
  end

  test "create resets failed login attempts on successful login" do
    @user.update!(failed_login_attempts: 3, locked_at: nil)

    post session_path, params: { email_address: @user.email_address, password: "password123" }

    @user.reload
    assert_equal 0, @user.failed_login_attempts
    assert_nil @user.locked_at
  end

  test "create normalizes email address (case insensitive)" do
    post session_path, params: { email_address: @user.email_address.upcase, password: "password123" }

    assert_redirected_to root_path
    user = User.find_by(email_address: @user.email_address)
    assert user.sessions.active.any?, "Session should be created after login"
  end

  test "create normalizes email address (strips whitespace)" do
    post session_path, params: { email_address: "  #{@user.email_address}  ", password: "password123" }

    assert_redirected_to root_path
    user = User.find_by(email_address: @user.email_address)
    assert user.sessions.active.any?, "Session should be created after login"
  end

  test "create redirects to return_to URL after successful login" do
    # Set return_to in session (simulating redirect from protected page)
    # This simulates what happens when require_authentication redirects to login
    get users_path # This should redirect to login if not authenticated
    follow_redirect! # Follow to login page
    # Now session should have return_to_after_authenticating set

    post session_path, params: { email_address: @user.email_address, password: "password123" }

    # Should redirect to the original URL (users_path)
    assert_redirected_to users_path
  end

  test "destroy without authentication redirects to login" do
    delete session_path

    assert_redirected_to new_session_path
  end

  test "create respects rate limit" do
    # Clear cache to ensure clean state
    Rails.cache.clear

    # Use non-existent user to avoid account locking
    nonexistent_email = "ratelimit@example.com"

    # Make 10 requests (within the limit)
    10.times do
      post session_path, params: { email_address: nonexistent_email, password: "wrongpassword" }
      assert_redirected_to new_session_path, "Request should succeed within rate limit"
    end

    # 11th request should be rate limited
    post session_path, params: { email_address: nonexistent_email, password: "wrongpassword" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_equal "Try again later.", flash[:alert]
  end

  test "rate limit resets after time window" do
    # Clear cache to ensure clean state
    Rails.cache.clear

    # Use non-existent user to avoid account locking
    nonexistent_email = "ratelimit2@example.com"

    # Make 10 requests to hit the limit
    10.times do
      post session_path, params: { email_address: nonexistent_email, password: "wrongpassword" }
    end

    # 11th request should be rate limited
    post session_path, params: { email_address: nonexistent_email, password: "wrongpassword" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_equal "Try again later.", flash[:alert]

    # Travel forward in time past the rate limit window (3 minutes)
    travel_to 4.minutes.from_now do
      # Request should succeed again after time window
      post session_path, params: { email_address: nonexistent_email, password: "wrongpassword" }
      assert_redirected_to new_session_path
      # Should not be rate limited, should show authentication error instead
      follow_redirect!
      assert_not_equal "Try again later.", flash[:alert]
      assert_match(/Invalid email address or password/i, flash[:alert].to_s)
    end
  end

  test "rate limit only applies to create action" do
    # Clear cache to ensure clean state
    Rails.cache.clear

    # Make many requests to new action (should not be rate limited)
    20.times do
      get new_session_path
      assert_response :success, "new action should not be rate limited"
    end
  end

  test "create sets last_activity_at on login" do
    post session_path, params: { email_address: @user.email_address, password: "password123" }

    assert_redirected_to root_path
    user = User.find_by(email_address: @user.email_address)
    session = user.sessions.active.order(created_at: :desc).first
    assert_not_nil session.last_activity_at, "last_activity_at should be set on login"
    assert_in_delta Time.current.to_i, session.last_activity_at.to_i, 5, "last_activity_at should be approximately now"
  end

  test "last_activity_at is updated when more than 1 minute has passed" do
    # Login first
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to root_path

    user = User.find_by(email_address: @user.email_address)
    session = user.sessions.active.order(created_at: :desc).first
    initial_time = session.last_activity_at
    assert_not_nil initial_time, "last_activity_at should be set on login"

    # Travel forward in time more than 1 minute
    travel_to 2.minutes.from_now do
      # Make a request to trigger after_fetch callback
      get root_path
      assert_response :success

      # Reload session and check last_activity_at was updated
      session.reload
      assert_not_nil session.last_activity_at, "last_activity_at should still be set"
      assert session.last_activity_at > initial_time, "last_activity_at should be updated after 1 minute"
      assert_in_delta Time.current.to_i, session.last_activity_at.to_i, 5, "last_activity_at should be approximately now"
    end
  end

  test "last_activity_at is not updated when less than 1 minute has passed" do
    # Login first
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to root_path

    user = User.find_by(email_address: @user.email_address)
    session = user.sessions.active.order(created_at: :desc).first
    initial_time = session.last_activity_at
    assert_not_nil initial_time, "last_activity_at should be set on login"

    # Travel forward in time less than 1 minute
    travel_to 30.seconds.from_now do
      # Make a request to trigger after_fetch callback
      get root_path
      assert_response :success

      # Reload session and check last_activity_at was NOT updated
      session.reload
      assert_equal initial_time.to_i, session.last_activity_at.to_i, "last_activity_at should not be updated within 1 minute"
    end
  end

  test "last_activity_at is updated when nil" do
    # Login first
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to root_path

    user = User.find_by(email_address: @user.email_address)
    session = user.sessions.active.order(created_at: :desc).first
    # Manually set last_activity_at to nil to simulate old session
    session.update_column(:last_activity_at, nil)

    # Make a request to trigger after_fetch callback
    get root_path
    assert_response :success

    # Reload session and check last_activity_at was set
    session.reload
    assert_not_nil session.last_activity_at, "last_activity_at should be set when nil"
    assert_in_delta Time.current.to_i, session.last_activity_at.to_i, 5, "last_activity_at should be approximately now"
  end
end
