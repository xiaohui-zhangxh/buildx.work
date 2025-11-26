require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:one)
    @admin.add_role("admin") unless @admin.has_role?("admin")

    @regular_user = users(:two)
    @other_user = User.create!(
      email_address: "other@example.com",
      password: "password123",
      name: "Other User"
    )
  end

  test "admin can index users" do
    policy = UserPolicy.new(nil, user: @admin)
    assert policy.index?
  end

  test "regular user cannot index users" do
    policy = UserPolicy.new(nil, user: @regular_user)
    assert_not policy.index?
  end

  test "anonymous user cannot index users" do
    policy = UserPolicy.new(nil, user: nil)
    assert_not policy.index?
  end

  test "admin can show any user" do
    policy = UserPolicy.new(@other_user, user: @admin)
    assert policy.show?
  end

  test "user can show themselves" do
    policy = UserPolicy.new(@regular_user, user: @regular_user)
    assert policy.show?
  end

  test "user cannot show other users" do
    policy = UserPolicy.new(@other_user, user: @regular_user)
    assert_not policy.show?
  end

  test "anonymous user cannot show users" do
    policy = UserPolicy.new(@other_user, user: nil)
    assert_not policy.show?
  end

  test "admin can create users" do
    policy = UserPolicy.new(nil, user: @admin)
    assert policy.create?
  end

  test "anonymous user can create users when system not installed" do
    SystemConfig.set("installation_completed", "0")
    policy = UserPolicy.new(nil, user: nil)
    assert policy.create?
  end

  test "anonymous user cannot create users when system installed" do
    SystemConfig.set("installation_completed", "1")
    policy = UserPolicy.new(nil, user: nil)
    assert_not policy.create?
  end

  test "admin can update any user" do
    policy = UserPolicy.new(@other_user, user: @admin)
    assert policy.update?
  end

  test "user can update themselves" do
    policy = UserPolicy.new(@regular_user, user: @regular_user)
    assert policy.update?
  end

  test "user cannot update other users" do
    policy = UserPolicy.new(@other_user, user: @regular_user)
    assert_not policy.update?
  end

  test "anonymous user cannot update users" do
    policy = UserPolicy.new(@other_user, user: nil)
    assert_not policy.update?
  end

  test "admin can destroy users" do
    policy = UserPolicy.new(@other_user, user: @admin)
    assert policy.destroy?
  end

  test "regular user cannot destroy users" do
    policy = UserPolicy.new(@other_user, user: @regular_user)
    assert_not policy.destroy?
  end

  test "user cannot destroy themselves" do
    policy = UserPolicy.new(@regular_user, user: @regular_user)
    assert_not policy.destroy?
  end

  test "anonymous user cannot destroy users" do
    policy = UserPolicy.new(@other_user, user: nil)
    assert_not policy.destroy?
  end

  test "admin can manage users" do
    policy = UserPolicy.new(@other_user, user: @admin)
    assert policy.manage?
  end

  test "regular user cannot manage users" do
    policy = UserPolicy.new(@other_user, user: @regular_user)
    assert_not policy.manage?
  end

  test "anonymous user cannot manage users" do
    policy = UserPolicy.new(@other_user, user: nil)
    assert_not policy.manage?
  end
end
