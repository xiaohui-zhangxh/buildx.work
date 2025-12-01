require "test_helper"

module Admin
  class AuditLogsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = users(:one)
      @admin.add_role("admin") unless @admin.has_role?("admin")
      @admin.update!(password: "password123", password_confirmation: "password123")

      @regular_user = users(:two)
      @regular_user.update!(password: "password123", password_confirmation: "password123")

      @audit_log = AuditLog.create!(
        user: @admin,
        action: "create",
        resource_type: "User",
        resource_id: 1,
        ip_address: "127.0.0.1",
        user_agent: "Test Agent"
      )
    end

    test "should redirect to login if not authenticated" do
      get admin_audit_logs_url
      assert_redirected_to new_session_path
    end

    test "should return 403 if not admin" do
      sign_in_as(@regular_user)
      get admin_audit_logs_url
      assert_response :forbidden
    end

    test "should show audit logs index for admin" do
      sign_in_as(@admin)
      get admin_audit_logs_url
      assert_response :success
      assert_select "h1", text: "操作日志"
    end

    test "should show audit log details for admin" do
      sign_in_as(@admin)
      get admin_audit_log_url(@audit_log)
      assert_response :success
      assert_match @audit_log.action, response.body
    end

    test "should filter audit logs by search" do
      sign_in_as(@admin)
      get admin_audit_logs_url, params: { search: @admin.email_address }
      assert_response :success
    end

    test "should filter audit logs by action" do
      sign_in_as(@admin)
      get admin_audit_logs_url, params: { action_filter: "create" }
      assert_response :success
    end

    test "should filter audit logs by resource type" do
      sign_in_as(@admin)
      get admin_audit_logs_url, params: { resource_type: "User" }
      assert_response :success
    end

    test "should filter audit logs by date range" do
      sign_in_as(@admin)
      get admin_audit_logs_url, params: {
        start_date: 1.week.ago.to_date.to_s,
        end_date: Time.current.to_date.to_s
      }
      assert_response :success
    end

    test "should export audit logs as CSV" do
      sign_in_as(@admin)
      # Create another audit log for testing
      AuditLog.create!(
        user: @admin,
        action: "update",
        resource_type: "Role",
        resource_id: 1,
        ip_address: "127.0.0.1",
        user_agent: "Test Agent 2"
      )

      get admin_audit_logs_url(format: :csv)
      assert_response :success
      assert_equal "text/csv", response.content_type
      assert_match(/时间.*用户.*操作.*资源类型/, response.body)
      assert_match(/create/, response.body)
      assert_match(/update/, response.body)
    end

    test "should handle CSV export with no logs" do
      sign_in_as(@admin)
      AuditLog.destroy_all

      get admin_audit_logs_url(format: :csv)
      assert_response :success
      assert_equal "text/csv", response.content_type
      assert_match(/时间.*用户.*操作.*资源类型/, response.body)
    end

    test "should handle show with non-existent audit log" do
      sign_in_as(@admin)
      get admin_audit_log_url(999999)
      assert_response :not_found
    end

    test "should filter audit logs by start_date only" do
      sign_in_as(@admin)
      get admin_audit_logs_url, params: {
        start_date: 1.week.ago.to_date.to_s
      }
      assert_response :success
    end

    test "should filter audit logs by end_date only" do
      sign_in_as(@admin)
      get admin_audit_logs_url, params: {
        end_date: Time.current.to_date.to_s
      }
      assert_response :success
    end

    test "should combine multiple filters" do
      sign_in_as(@admin)
      get admin_audit_logs_url, params: {
        search: @admin.email_address,
        action_filter: "create",
        resource_type: "User",
        start_date: 1.week.ago.to_date.to_s,
        end_date: Time.current.to_date.to_s
      }
      assert_response :success
    end

    test "should export CSV with filtered results" do
      sign_in_as(@admin)
      get admin_audit_logs_url(format: :csv), params: {
        action_filter: "create"
      }
      assert_response :success
      assert_equal "text/csv", response.content_type
      assert_match(/create/, response.body)
    end
  end
end
