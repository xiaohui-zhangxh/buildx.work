require "test_helper"

class RolePolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:one)
    @admin.add_role("admin") unless @admin.has_role?("admin")

    @regular_user = users(:two)
    @role = roles(:admin)
  end

  test "admin can index roles" do
    policy = RolePolicy.new(nil, user: @admin)
    assert policy.index?
  end

  test "regular user cannot index roles" do
    policy = RolePolicy.new(nil, user: @regular_user)
    assert_not policy.index?
  end

  test "anonymous user cannot index roles" do
    policy = RolePolicy.new(nil, user: nil)
    assert_not policy.index?
  end

  test "admin can show roles" do
    policy = RolePolicy.new(@role, user: @admin)
    assert policy.show?
  end

  test "regular user cannot show roles" do
    policy = RolePolicy.new(@role, user: @regular_user)
    assert_not policy.show?
  end

  test "anonymous user cannot show roles" do
    policy = RolePolicy.new(@role, user: nil)
    assert_not policy.show?
  end

  test "admin can create roles" do
    policy = RolePolicy.new(nil, user: @admin)
    assert policy.create?
  end

  test "regular user cannot create roles" do
    policy = RolePolicy.new(nil, user: @regular_user)
    assert_not policy.create?
  end

  test "anonymous user cannot create roles" do
    policy = RolePolicy.new(nil, user: nil)
    assert_not policy.create?
  end

  test "admin can update roles" do
    policy = RolePolicy.new(@role, user: @admin)
    assert policy.update?
  end

  test "regular user cannot update roles" do
    policy = RolePolicy.new(@role, user: @regular_user)
    assert_not policy.update?
  end

  test "anonymous user cannot update roles" do
    policy = RolePolicy.new(@role, user: nil)
    assert_not policy.update?
  end

  test "admin can destroy roles" do
    policy = RolePolicy.new(@role, user: @admin)
    assert policy.destroy?
  end

  test "regular user cannot destroy roles" do
    policy = RolePolicy.new(@role, user: @regular_user)
    assert_not policy.destroy?
  end

  test "anonymous user cannot destroy roles" do
    policy = RolePolicy.new(@role, user: nil)
    assert_not policy.destroy?
  end

  test "admin can manage roles" do
    policy = RolePolicy.new(@role, user: @admin)
    assert policy.manage?
  end

  test "regular user cannot manage roles" do
    policy = RolePolicy.new(@role, user: @regular_user)
    assert_not policy.manage?
  end

  test "anonymous user cannot manage roles" do
    policy = RolePolicy.new(@role, user: nil)
    assert_not policy.manage?
  end
end
