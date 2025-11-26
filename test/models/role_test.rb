require "test_helper"

class RoleTest < ActiveSupport::TestCase
  def setup
    @role = roles(:admin)
  end

  test "should be valid" do
    assert @role.valid?
  end

  test "should require name" do
    @role.name = nil
    assert_not @role.valid?
    assert_includes @role.errors[:name], "不能为空字符"
  end

  test "should have unique name" do
    duplicate_role = Role.new(name: @role.name, description: "Duplicate")
    assert_not duplicate_role.valid?
    assert_includes duplicate_role.errors[:name], "已经被使用"
  end

  test "should have many user_roles" do
    assert_respond_to @role, :user_roles
  end

  test "should have many users through user_roles" do
    assert_respond_to @role, :users
  end

  test "should destroy associated user_roles when destroyed" do
    user = users(:one)
    user.add_role(@role.name)
    assert_difference "UserRole.count", -1 do
      @role.destroy
    end
  end

  test "should validate name format" do
    invalid_role = Role.new(name: "Invalid-Role", description: "Invalid")
    assert_not invalid_role.valid?
    assert_includes invalid_role.errors[:name], "must be lowercase letters, numbers, and underscores only"

    invalid_role2 = Role.new(name: "123invalid", description: "Invalid")
    assert_not invalid_role2.valid?
    assert_includes invalid_role2.errors[:name], "must be lowercase letters, numbers, and underscores only"

    valid_role = Role.new(name: "valid_role_123", description: "Valid")
    assert valid_role.valid?
  end

  test "should allow valid name formats" do
    # Use unique names to avoid uniqueness conflicts
    timestamp = Time.current.to_i
    valid_names = [ "admin_#{timestamp}", "editor_#{timestamp}", "user_role_#{timestamp}", "role_123_#{timestamp}", "a_#{timestamp}", "a1_#{timestamp}", "_role_#{timestamp}" ]
    valid_names.each do |name|
      role = Role.new(name: name, description: "Test")
      assert role.valid?, "#{name} should be valid"
    end
  end

  test "should reject invalid name formats" do
    invalid_names = [ "Admin", "ROLE", "role-name", "role.name", "role name", "123role", "" ]
    invalid_names.each do |name|
      role = Role.new(name: name, description: "Test")
      assert_not role.valid?, "#{name} should be invalid"
      assert_includes role.errors[:name], "must be lowercase letters, numbers, and underscores only"
    end
  end
end
