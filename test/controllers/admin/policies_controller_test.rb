require "test_helper"

module Admin
  class PoliciesControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = users(:one)
      @admin.add_role("admin") unless @admin.has_role?("admin")
      @admin.update!(password: "password123", password_confirmation: "password123")

      @regular_user = users(:two)
      @regular_user.update!(password: "password123", password_confirmation: "password123")
    end

    test "should redirect to login if not authenticated" do
      get admin_policies_url
      assert_redirected_to new_session_path
    end

    test "should return 403 if not admin" do
      sign_in_as(@regular_user)
      get admin_policies_url
      assert_response :forbidden
    end

    test "should show policies index for admin" do
      sign_in_as(@admin)
      get admin_policies_url
      assert_response :success
      assert_select "h1", text: "权限说明"
    end

    test "should show policy details for admin" do
      sign_in_as(@admin)
      get admin_policy_url("UserPolicy")
      assert_response :success
      assert_match "UserPolicy", response.body
    end

    test "should redirect if policy not found" do
      sign_in_as(@admin)
      get admin_policy_url("NonExistentPolicy")
      assert_redirected_to admin_policies_path
      follow_redirect!
      assert_match(/权限策略不存在/, flash[:alert])
    end

    test "should show RolePolicy details" do
      sign_in_as(@admin)
      get admin_policy_url("RolePolicy")
      assert_response :success
      assert_match "RolePolicy", response.body
      assert_match "角色资源权限策略", response.body
    end

    test "should show AdminPolicy details" do
      sign_in_as(@admin)
      get admin_policy_url("AdminPolicy")
      assert_response :success
      assert_match "AdminPolicy", response.body
      assert_match "管理后台权限策略", response.body
    end
  end
end
