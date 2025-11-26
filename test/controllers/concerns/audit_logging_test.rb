require "test_helper"

class AuditLoggingTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.add_role("admin") unless @admin.has_role?("admin")
    @admin.update!(password: "password123", password_confirmation: "password123", confirmed_at: Time.current)

    @regular_user = users(:two)
    @regular_user.update!(password: "password123", password_confirmation: "password123", confirmed_at: Time.current)

    # Ensure system is installed
    SystemConfig.set("installation_completed", "true", description: "系统安装完成", category: "system") unless SystemConfig.installation_completed?
  end

  test "log_action creates audit log for create action" do
    sign_in_as(@admin)
    # Admin::UsersController doesn't have create action, so test with Admin::RolesController instead
    AuditLog.destroy_all
    initial_count = AuditLog.count
    unique_name = "new_role_#{Time.current.to_i}_#{rand(10000)}"

    post admin_roles_path, params: {
      role: {
        name: unique_name,
        description: "New Role"
      }
    }

    # Follow redirect to ensure response is successful
    follow_redirect! if response.redirect?
    assert_response :success
    
    # Check AuditLog was created
    assert_equal initial_count + 1, AuditLog.count, "AuditLog should be created after successful role creation"
    log = AuditLog.last
    assert_equal "create", log.action
    assert_equal "Role", log.resource_type
    assert_not_nil log.resource_id
    assert_equal @admin, log.user
  end

  test "log_action creates audit log for update action" do
    sign_in_as(@admin)
    user = User.create!(
      email_address: "testuser@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      confirmed_at: Time.current
    )
    AuditLog.destroy_all
    initial_count = AuditLog.count

    patch admin_user_path(user), params: {
      user: {
        name: "Updated Name"
      }
    }

    # Check AuditLog was created (after_action runs before follow_redirect)
    assert_equal initial_count + 1, AuditLog.count
    log = AuditLog.last
    assert_equal "update", log.action
    assert_equal "User", log.resource_type
    assert_equal user.id, log.resource_id
    assert_equal @admin, log.user
    assert_not_nil log.changes_data
    
    # Verify redirect happened
    assert_redirected_to admin_user_path(user)
  end

  test "log_action creates audit log for batch_destroy action" do
    sign_in_as(@admin)
    user1 = User.create!(
      email_address: "user1@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "User 1",
      confirmed_at: Time.current
    )
    user2 = User.create!(
      email_address: "user2@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "User 2",
      confirmed_at: Time.current
    )
    AuditLog.destroy_all
    initial_count = AuditLog.count

    post batch_destroy_admin_users_path, params: {
      user_ids: [ user1.id, user2.id ]
    }

    # Check AuditLog was created (after_action runs before follow_redirect)
    assert_equal initial_count + 1, AuditLog.count
    log = AuditLog.last
    assert_equal "batch_destroy", log.action
    assert_equal @admin, log.user
    assert_not_nil log.changes_data
    # changes_data is JSON serialized, so use string keys
    assert_equal 2, log.changes_data["count"] || log.changes_data[:count]
    
    # Verify redirect happened
    assert_redirected_to admin_users_path
  end

  test "log_action creates audit log for batch_assign_role action" do
    sign_in_as(@admin)
    role = Role.create!(name: "editor", description: "Editor")
    user = User.create!(
      email_address: "testuser@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      confirmed_at: Time.current
    )
    AuditLog.destroy_all
    initial_count = AuditLog.count

    post batch_assign_role_admin_users_path, params: {
      user_ids: [ user.id ],
      role_name: role.name
    }

    # Check AuditLog was created (after_action runs before follow_redirect)
    assert_equal initial_count + 1, AuditLog.count
    log = AuditLog.last
    assert_equal "batch_assign_role", log.action
    assert_equal @admin, log.user
    assert_not_nil log.changes_data
    # changes_data is JSON serialized, so use string keys
    assert_equal role.name, log.changes_data["role_name"] || log.changes_data[:role_name]
    
    # Verify redirect happened
    assert_redirected_to admin_users_path
  end

  test "log_action creates audit log for batch_remove_role action" do
    sign_in_as(@admin)
    role = Role.create!(name: "editor", description: "Editor")
    user = User.create!(
      email_address: "testuser@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      confirmed_at: Time.current
    )
    user.add_role(role.name)
    AuditLog.destroy_all
    initial_count = AuditLog.count

    post batch_remove_role_admin_users_path, params: {
      user_ids: [ user.id ],
      role_name: role.name
    }

    # Check AuditLog was created (after_action runs before follow_redirect)
    assert_equal initial_count + 1, AuditLog.count
    log = AuditLog.last
    assert_equal "batch_remove_role", log.action
    assert_equal @admin, log.user
    assert_not_nil log.changes_data
    # changes_data is JSON serialized, so use string keys
    assert_equal role.name, log.changes_data["role_name"] || log.changes_data[:role_name]
    
    # Verify redirect happened
    assert_redirected_to admin_users_path
  end

  test "log_action does not log failed actions" do
    sign_in_as(@admin)

    # Try to create user with invalid data (should fail)
    assert_no_difference "AuditLog.count" do
      post admin_users_path, params: {
        user: {
          email_address: "", # Invalid: empty
          password: "short", # Invalid: too short
          name: "A" # Invalid: too short
        }
      }
    end
  end

  test "log_destroy creates audit log before destruction" do
    sign_in_as(@admin)
    user = User.create!(
      email_address: "testuser@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      confirmed_at: Time.current
    )
    AuditLog.destroy_all
    initial_count = AuditLog.count

    # Note: log_destroy is called in before_destroy callback
    # We test it indirectly through the destroy action
    delete admin_user_path(user)

    # Check AuditLog was created (log_destroy runs before destroy, before redirect)
    assert_equal initial_count + 1, AuditLog.count
    log = AuditLog.last
    assert_equal "destroy", log.action
    assert_equal "User", log.resource_type
    assert_equal user.id, log.resource_id
    assert_equal @admin, log.user
    
    # Verify redirect happened
    assert_redirected_to admin_users_path
  end
end

