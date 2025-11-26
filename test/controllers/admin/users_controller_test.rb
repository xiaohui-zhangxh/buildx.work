require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = users(:one)
      @admin.add_role("admin") unless @admin.has_role?("admin")
      @admin.update!(password: "password123", password_confirmation: "password123")

      @regular_user = users(:two)
      @regular_user.update!(password: "password123", password_confirmation: "password123")

      @other_user = User.create!(
        email_address: "other@example.com",
        password: "password123",
        name: "Other User",
        confirmed_at: Time.current
      )
    end

    test "should redirect to login if not authenticated" do
      get admin_users_url
      assert_redirected_to new_session_path
    end

    test "should return 403 if not admin" do
      sign_in_as(@regular_user)
      get admin_users_url
      assert_response :forbidden
    end

    test "should show users index for admin" do
      sign_in_as(@admin)
      get admin_users_url
      assert_response :success
      assert_select "h1", text: "用户管理"
    end

    test "should show user details for admin" do
      sign_in_as(@admin)
      get admin_user_url(@other_user)
      assert_response :success
      assert_match @other_user.email_address, response.body
    end

    test "should show edit user form for admin" do
      sign_in_as(@admin)
      get edit_admin_user_url(@other_user)
      assert_response :success
      assert_select "form"
    end

    test "should update user for admin" do
      sign_in_as(@admin)
      patch admin_user_url(@other_user), params: {
        user: {
          name: "Updated Name",
          email_address: @other_user.email_address
        }
      }
      assert_redirected_to admin_user_path(@other_user)
      @other_user.reload
      assert_equal "Updated Name", @other_user.name
    end

    test "should destroy user for admin" do
      sign_in_as(@admin)
      assert_difference "User.count", -1 do
        delete admin_user_url(@other_user)
      end
      assert_redirected_to admin_users_path
    end

    test "should not allow regular user to access users index" do
      sign_in_as(@regular_user)
      get admin_users_url
      assert_response :forbidden
    end
  end
end
