require "test_helper"

module My
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @user.update!(password: "password123", password_confirmation: "password123")
    end

    test "show requires authentication" do
      get my_root_path
      assert_redirected_to new_session_path
    end

    test "show displays dashboard when authenticated" do
      sign_in_as(@user)

      get my_root_path
      assert_response :success
      assert_select "h1", text: /个人中心/
    end

    test "show displays user statistics" do
      # Create some sessions for the user
      @user.sign_in!("User Agent 1", "192.168.1.1")
      @user.sign_in!("User Agent 2", "192.168.1.2")
      session = @user.sessions.last
      session.update!(active: false) # Make one inactive

      sign_in_as(@user)

      get my_root_path
      assert_response :success
      assert_select ".stat", count: 3 # Should have 3 stat cards
      assert_select ".stat-title", text: /活跃会话/
      assert_select ".stat-title", text: /总会话数/
      assert_select ".stat-title", text: /密码状态/
    end

    test "show displays recent sessions" do
      # Create multiple sessions
      3.times do |i|
        @user.sign_in!("User Agent #{i}", "192.168.1.#{i}")
      end

      sign_in_as(@user)

      get my_root_path
      assert_response :success
      # Should show recent sessions table
      assert_select "table.table"
    end

    test "show displays password expiration warning when password expired" do
      @user.update!(password_changed_at: 100.days.ago)
      sign_in_as(@user)

      get my_root_path
      assert_response :success
      assert_select ".alert-error", text: /密码已过期/
    end

    test "show displays password expiration warning when password expires soon" do
      @user.update!(password_changed_at: 85.days.ago) # 5 days before expiration
      sign_in_as(@user)

      get my_root_path
      assert_response :success
      assert_select ".alert-warning", text: /密码即将过期/
    end

    test "show does not display password warning when password is normal" do
      @user.update!(password_changed_at: 30.days.ago)
      sign_in_as(@user)

      get my_root_path
      assert_response :success
      assert_select ".alert-error", count: 0
      assert_select ".alert-warning", count: 0
    end

    test "show displays correct session counts" do
      # Create active and inactive sessions
      @user.sign_in!("User Agent 1", "192.168.1.1")
      @user.sign_in!("User Agent 2", "192.168.1.2")
      session = @user.sessions.last
      session.update!(active: false)

      sign_in_as(@user)

      get my_root_path
      assert_response :success
      # Should show 1 active session (current one) + 1 from sign_in
      # Actually, sign_in_as creates a session, so we have current + 2 created = 3 total, 2 active
      assert_select ".stat-value", text: /2/ # Active sessions
    end
  end
end
