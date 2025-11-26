require "test_helper"
require "ostruct"

class AuditLogTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    # Clean up audit logs before each test to avoid interference
    AuditLog.destroy_all
  end

  test "validates action presence" do
    log = AuditLog.new(user: @user)
    assert_not log.valid?
    assert_includes log.errors[:action], "不能为空字符"
  end

  test "belongs to user" do
    log = AuditLog.create!(
      user: @user,
      action: "create",
      resource_type: "User",
      resource_id: 1
    )

    assert_equal @user, log.user
  end

  test "serializes changes_data as JSON" do
    changes = { "name" => [ "Old", "New" ], "email" => [ "old@example.com", "new@example.com" ] }
    log = AuditLog.create!(
      user: @user,
      action: "update",
      changes_data: changes
    )

    reloaded_changes = log.reload.changes_data
    assert_equal changes, reloaded_changes
    assert_kind_of Hash, reloaded_changes
  end

  test "recent scope orders by created_at desc" do
    log1 = AuditLog.create!(user: @user, action: "create")
    log1.update_column(:created_at, 2.days.ago)
    log2 = AuditLog.create!(user: @user, action: "update")
    log2.update_column(:created_at, 1.day.ago)
    log3 = AuditLog.create!(user: @user, action: "destroy")

    recent_logs = AuditLog.recent.to_a

    assert_equal log3.id, recent_logs.first.id
    assert_equal log2.id, recent_logs.second.id
    assert_equal log1.id, recent_logs.third.id
  end

  test "by_action scope filters by action" do
    AuditLog.create!(user: @user, action: "create")
    AuditLog.create!(user: @user, action: "update")
    AuditLog.create!(user: @user, action: "create")

    create_logs = AuditLog.by_action("create")

    assert_equal 2, create_logs.count
    assert create_logs.all? { |log| log.action == "create" }
  end

  test "by_resource scope filters by resource_type" do
    AuditLog.create!(user: @user, action: "create", resource_type: "User", resource_id: 1)
    AuditLog.create!(user: @user, action: "create", resource_type: "Role", resource_id: 1)
    AuditLog.create!(user: @user, action: "create", resource_type: "User", resource_id: 2)

    user_logs = AuditLog.by_resource("User")

    assert_equal 2, user_logs.count
    assert user_logs.all? { |log| log.resource_type == "User" }
  end

  test "by_resource scope filters by resource_type and resource_id" do
    AuditLog.create!(user: @user, action: "create", resource_type: "User", resource_id: 1)
    AuditLog.create!(user: @user, action: "update", resource_type: "User", resource_id: 1)
    AuditLog.create!(user: @user, action: "create", resource_type: "User", resource_id: 2)

    user_1_logs = AuditLog.by_resource("User", 1)

    assert_equal 2, user_1_logs.count
    assert user_1_logs.all? { |log| log.resource_type == "User" && log.resource_id == 1 }
  end

  test "by_user scope filters by user" do
    other_user = users(:two)
    AuditLog.create!(user: @user, action: "create")
    AuditLog.create!(user: other_user, action: "create")
    AuditLog.create!(user: @user, action: "update")

    user_logs = AuditLog.by_user(@user)

    assert_equal 2, user_logs.count
    assert user_logs.all? { |log| log.user == @user }
  end

  test "log creates audit log entry with all parameters" do
    resource = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      confirmed_at: Time.current
    )
    changes = { "name" => [ "Old", "New" ] }
    request = OpenStruct.new(remote_ip: "127.0.0.1", user_agent: "Test Agent")

    log = AuditLog.log(
      user: @user,
      action: :create,
      resource: resource,
      changes: changes,
      request: request,
      controller_name: "users",
      action_name: "create"
    )

    assert_equal @user, log.user
    assert_equal "create", log.action
    assert_equal "User", log.resource_type
    assert_equal resource.id, log.resource_id
    assert_equal changes, log.changes_data
    assert_equal "127.0.0.1", log.ip_address
    assert_equal "Test Agent", log.user_agent
    assert_equal "users", log.controller_name
    assert_equal "create", log.action_name
  end

  test "log converts action to string" do
    log = AuditLog.log(user: @user, action: :update)

    assert_equal "update", log.action
    assert_kind_of String, log.action
  end

  test "log handles nil resource" do
    log = AuditLog.log(user: @user, action: "index")

    assert_nil log.resource_type
    assert_nil log.resource_id
  end

  test "log handles nil request" do
    log = AuditLog.log(user: @user, action: "create")

    assert_nil log.ip_address
    assert_nil log.user_agent
  end

  test "log handles nil changes" do
    log = AuditLog.log(user: @user, action: "index")

    assert_nil log.changes_data
  end
end
