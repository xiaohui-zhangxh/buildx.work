require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    # Clear cache to ensure clean state for rate limiting
    Rails.cache.clear

    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    # Clear cache to ensure clean state for rate limiting
    Rails.cache.clear

    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "newpass123", password_confirmation: "newpass123" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Password has been reset"
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "newpass123", password_confirmation: "different123" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_notice "Passwords did not match"
  end

  test "create respects rate limit" do
    # Clear cache to ensure clean state
    Rails.cache.clear

    # Make 10 requests (the limit)
    10.times do
      post passwords_path, params: { email_address: @user.email_address }
      assert_redirected_to new_session_path, "Request should succeed within rate limit"
    end

    # 11th request should be rate limited
    post passwords_path, params: { email_address: @user.email_address }
    assert_redirected_to new_password_path
    follow_redirect!
    assert_match(/Try again later/, response.body)
  end

  test "rate limit only applies to create action" do
    # Clear cache to ensure clean state
    Rails.cache.clear

    # Make 10 create requests to hit the limit
    10.times do
      post passwords_path, params: { email_address: @user.email_address }
    end

    # Other actions should still work
    get new_password_path
    assert_response :success

    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "update destroys all user sessions" do
    # Create multiple sessions for the user
    session1 = @user.sign_in!("User Agent 1", "192.168.1.1")
    session2 = @user.sign_in!("User Agent 2", "192.168.1.2")

    assert_equal 2, @user.sessions.count

    put password_path(@user.password_reset_token), params: {
      password: "newpass123",
      password_confirmation: "newpass123"
    }

    # All sessions should be destroyed
    assert_equal 0, @user.reload.sessions.count
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
