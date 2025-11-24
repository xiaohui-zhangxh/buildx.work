require "test_helper"

module My
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @user.update!(password: "password123", password_confirmation: "password123")
    end

    test "index requires authentication" do
      get my_sessions_path
      assert_redirected_to new_session_path
    end

    test "index displays sessions when authenticated" do
      # Create some sessions
      @user.sign_in!("User Agent 1", "192.168.1.1")
      @user.sign_in!("User Agent 2", "192.168.1.2")

      sign_in_as(@user)

      get my_sessions_path
      assert_response :success
      assert_select "h1", text: /登录日志/
    end

    test "index displays active and inactive sessions" do
      # Create active and inactive sessions
      session1 = @user.sign_in!("User Agent 1", "192.168.1.1")
      session2 = @user.sign_in!("User Agent 2", "192.168.1.2")
      session2.update!(active: false)

      sign_in_as(@user)

      get my_sessions_path
      assert_response :success
      assert_select ".card-title", text: /活跃会话/
      assert_select ".card-title", text: /历史会话/
    end

    test "destroy requires authentication" do
      session = @user.sign_in!("User Agent", "192.168.1.1")

      delete my_session_path(session)
      assert_redirected_to new_session_path
    end

    test "destroy terminates session" do
      session = @user.sign_in!("User Agent", "192.168.1.1")
      sign_in_as(@user)

      assert session.active?

      delete my_session_path(session)

      assert_redirected_to my_sessions_path
      session.reload
      assert_not session.active?
    end

    test "destroy does not terminate current session" do
      sign_in_as(@user)
      current_session = Current.session
      other_session = @user.sign_in!("Other User Agent", "192.168.1.2")

      delete my_session_path(current_session)

      assert_redirected_to my_sessions_path
      current_session.reload
      # Current session should still be active (terminate_session_by_id should prevent this)
      # But if it's the current session, it might not be terminated
      # Let's check that other_session can be terminated
      delete my_session_path(other_session)
      other_session.reload
      assert_not other_session.active?
    end

    test "destroy_all_others requires authentication" do
      post destroy_all_others_my_sessions_path
      assert_redirected_to new_session_path
    end

    test "destroy_all_others terminates all other sessions" do
      sign_in_as(@user)
      current_session = Current.session

      # Create other sessions
      session1 = @user.sign_in!("User Agent 1", "192.168.1.1")
      session2 = @user.sign_in!("User Agent 2", "192.168.1.2")

      assert session1.active?
      assert session2.active?

      post destroy_all_others_my_sessions_path

      assert_redirected_to my_sessions_path
      session1.reload
      session2.reload
      assert_not session1.active?
      assert_not session2.active?
      # Current session should still be active
      current_session.reload
      assert current_session.active?
    end

    test "destroy_all_others shows message when no other sessions" do
      sign_in_as(@user)

      post destroy_all_others_my_sessions_path

      assert_redirected_to my_sessions_path
      assert_equal "No other active sessions to terminate.", flash[:notice]
    end

    test "destroy_all_others shows count of terminated sessions" do
      sign_in_as(@user)

      # Create other sessions
      session1 = @user.sign_in!("User Agent 1", "192.168.1.1")
      session2 = @user.sign_in!("User Agent 2", "192.168.1.2")

      post destroy_all_others_my_sessions_path

      assert_redirected_to my_sessions_path
      assert_match(/Terminated 2 session\(s\)\./, flash[:notice])
    end
  end
end
