require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @role = roles(:admin)
    @user_role = UserRole.create!(user: @user, role: @role)
  end

  test "should be valid" do
    assert @user_role.valid?
  end

  test "should require user" do
    @user_role.user = nil
    assert_not @user_role.valid?
    assert_includes @user_role.errors[:user], "必须存在"
  end

  test "should require role" do
    @user_role.role = nil
    assert_not @user_role.valid?
    assert_includes @user_role.errors[:role], "必须存在"
  end

  test "should have unique user_id and role_id combination" do
    duplicate = UserRole.new(user: @user, role: @role)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "用户已经拥有该角色"
  end

  test "should belong to user" do
    assert_equal @user, @user_role.user
  end

  test "should belong to role" do
    assert_equal @role, @user_role.role
  end
end
