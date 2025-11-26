require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = users(:one)
      @admin.add_role("admin") unless @admin.has_role?("admin")
      @admin.update!(password: "password123", password_confirmation: "password123")

      @regular_user = users(:two)
      @regular_user.update!(password: "password123", password_confirmation: "password123")
    end

    test "should redirect to login if not authenticated" do
      get admin_root_url
      assert_redirected_to new_session_path
    end

    test "should return 403 if not admin" do
      sign_in_as(@regular_user)
      get admin_root_url
      assert_response :forbidden
    end

    test "should show dashboard for admin" do
      sign_in_as(@admin)
      get admin_root_url
      assert_response :success
      assert_select "h1", text: "仪表盘"
    end

    test "should display user count" do
      sign_in_as(@admin)
      get admin_root_url
      assert_response :success
      assert_match User.count.to_s, response.body
    end

    test "should display role count" do
      sign_in_as(@admin)
      get admin_root_url
      assert_response :success
      assert_match Role.count.to_s, response.body
    end

    test "should display recent users" do
      sign_in_as(@admin)
      get admin_root_url
      assert_response :success
      # Should show recent users table
      assert_select "table"
    end
  end
end
