require "test_helper"

module Admin
  class RolesControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = users(:one)
      @admin.add_role("admin") unless @admin.has_role?("admin")
      @admin.update!(password: "password123", password_confirmation: "password123")

      @regular_user = users(:two)
      @regular_user.update!(password: "password123", password_confirmation: "password123")

      @role = roles(:admin)
    end

    test "should redirect to login if not authenticated" do
      get admin_roles_url
      assert_redirected_to new_session_path
    end

    test "should return 403 if not admin" do
      sign_in_as(@regular_user)
      get admin_roles_url
      assert_response :forbidden
    end

    test "should show roles index for admin" do
      sign_in_as(@admin)
      get admin_roles_url
      assert_response :success
      assert_select "h1", text: "角色管理"
    end

    test "should show role details for admin" do
      sign_in_as(@admin)
      get admin_role_url(@role)
      assert_response :success
      assert_match @role.name, response.body
    end

    test "should show new role form for admin" do
      sign_in_as(@admin)
      get new_admin_role_url
      assert_response :success
      assert_select "form"
    end

    test "should create role for admin" do
      sign_in_as(@admin)
      assert_difference "Role.count", 1 do
        post admin_roles_url, params: {
          role: {
            name: "manager",
            description: "Manager role"
          }
        }
      end
      assert_redirected_to admin_role_path(Role.last)
    end

    test "should show edit role form for admin" do
      sign_in_as(@admin)
      get edit_admin_role_url(@role)
      assert_response :success
      assert_select "form"
    end

    test "should update role for admin" do
      sign_in_as(@admin)
      patch admin_role_url(@role), params: {
        role: {
          name: @role.name,
          description: "Updated description"
        }
      }
      assert_redirected_to admin_role_path(@role)
      @role.reload
      assert_equal "Updated description", @role.description
    end

    test "should destroy role for admin" do
      new_role = Role.create!(name: "test_role", description: "Test role")
      sign_in_as(@admin)
      assert_difference "Role.count", -1 do
        delete admin_role_url(new_role)
      end
      assert_redirected_to admin_roles_path
    end

    test "should not allow regular user to access roles index" do
      sign_in_as(@regular_user)
      get admin_roles_url
      assert_response :forbidden
    end
  end
end
