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

    test "should search users by email" do
      sign_in_as(@admin)
      get admin_users_url, params: { search: @other_user.email_address }
      assert_response :success
      assert_match @other_user.email_address, response.body
    end

    test "should search users by name" do
      sign_in_as(@admin)
      get admin_users_url, params: { search: @other_user.name }
      assert_response :success
      assert_match @other_user.name, response.body
    end

    test "should filter users by role" do
      role = roles(:admin)
      @other_user.add_role(role.name)
      sign_in_as(@admin)
      get admin_users_url, params: { role: role.name }
      assert_response :success
      assert_match @other_user.email_address, response.body
    end

    test "should batch destroy users" do
      user1 = User.create!(
        email_address: "batch1@example.com",
        password: "password123",
        name: "Batch User 1",
        confirmed_at: Time.current
      )
      user2 = User.create!(
        email_address: "batch2@example.com",
        password: "password123",
        name: "Batch User 2",
        confirmed_at: Time.current
      )
      sign_in_as(@admin)
      assert_difference "User.count", -2 do
        post batch_destroy_admin_users_url, params: { user_ids: [ user1.id, user2.id ] }
      end
      assert_redirected_to admin_users_path
    end

    test "should show alert when batch destroy with no users selected" do
      sign_in_as(@admin)
      post batch_destroy_admin_users_url, params: { user_ids: [] }
      assert_redirected_to admin_users_path
      # Alert message is set via flash
    end

    test "should batch assign role to users" do
      role = Role.create!(name: "editor", description: "Editor")
      user1 = User.create!(
        email_address: "batch1@example.com",
        password: "password123",
        name: "Batch User 1",
        confirmed_at: Time.current
      )
      user2 = User.create!(
        email_address: "batch2@example.com",
        password: "password123",
        name: "Batch User 2",
        confirmed_at: Time.current
      )
      sign_in_as(@admin)
      post batch_assign_role_admin_users_url, params: {
        user_ids: [ user1.id, user2.id ],
        role_name: role.name
      }
      assert_redirected_to admin_users_path
      assert user1.reload.has_role?(role.name)
      assert user2.reload.has_role?(role.name)
    end

    test "should show alert when batch assign role with no users selected" do
      sign_in_as(@admin)
      post batch_assign_role_admin_users_url, params: {
        user_ids: [],
        role_name: "editor"
      }
      assert_redirected_to admin_users_path
    end

    test "should batch remove role from users" do
      role = Role.create!(name: "editor", description: "Editor")
      user1 = User.create!(
        email_address: "batch1@example.com",
        password: "password123",
        name: "Batch User 1",
        confirmed_at: Time.current
      )
      user2 = User.create!(
        email_address: "batch2@example.com",
        password: "password123",
        name: "Batch User 2",
        confirmed_at: Time.current
      )
      user1.add_role(role.name)
      user2.add_role(role.name)
      sign_in_as(@admin)
      post batch_remove_role_admin_users_url, params: {
        user_ids: [ user1.id, user2.id ],
        role_name: role.name
      }
      assert_redirected_to admin_users_path
      assert_not user1.reload.has_role?(role.name)
      assert_not user2.reload.has_role?(role.name)
    end

    test "should show alert when batch remove role with no users selected" do
      sign_in_as(@admin)
      post batch_remove_role_admin_users_url, params: {
        user_ids: [],
        role_name: "editor"
      }
      assert_redirected_to admin_users_path
    end

    test "should update user without password" do
      sign_in_as(@admin)
      patch admin_user_url(@other_user), params: {
        user: {
          name: "Updated Name Without Password",
          email_address: @other_user.email_address
        }
      }
      assert_redirected_to admin_user_path(@other_user)
      @other_user.reload
      assert_equal "Updated Name Without Password", @other_user.name
    end

  test "should update user with password" do
    sign_in_as(@admin)
    patch admin_user_url(@other_user), params: {
      user: {
        name: @other_user.name,
        email_address: @other_user.email_address,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    assert_redirected_to admin_user_path(@other_user)
    assert @other_user.reload.authenticate("newpassword123")
  end

  test "should render edit when update fails" do
    sign_in_as(@admin)
    # Try to update with invalid email
    patch admin_user_url(@other_user), params: {
      user: {
        email_address: "invalid-email",
        name: @other_user.name
      }
    }
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "should show alert when batch assign role with no role name" do
    sign_in_as(@admin)
    user1 = User.create!(
      email_address: "batch1@example.com",
      password: "password123",
      name: "Batch User 1",
      confirmed_at: Time.current
    )
    post batch_assign_role_admin_users_url, params: {
      user_ids: [ user1.id ],
      role_name: ""
    }
    assert_redirected_to admin_users_path
    # Alert message is set via flash
  end

  test "should show alert when batch remove role with no role name" do
    sign_in_as(@admin)
    user1 = User.create!(
      email_address: "batch1@example.com",
      password: "password123",
      name: "Batch User 1",
      confirmed_at: Time.current
    )
    post batch_remove_role_admin_users_url, params: {
      user_ids: [ user1.id ],
      role_name: ""
    }
    assert_redirected_to admin_users_path
    # Alert message is set via flash
  end
  end
end
