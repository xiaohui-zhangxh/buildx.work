require "test_helper"

class AdminPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:one)
    @admin.add_role("admin") unless @admin.has_role?("admin")

    @regular_user = users(:two)
  end

  test "admin can access dashboard" do
    policy = AdminPolicy.new(nil, user: @admin)
    assert policy.dashboard?
  end

  test "regular user cannot access dashboard" do
    policy = AdminPolicy.new(nil, user: @regular_user)
    assert_not policy.dashboard?
  end

  test "anonymous user cannot access dashboard" do
    policy = AdminPolicy.new(nil, user: nil)
    assert_not policy.dashboard?
  end

  test "admin can manage admin area" do
    policy = AdminPolicy.new(nil, user: @admin)
    assert policy.manage?
  end

  test "regular user cannot manage admin area" do
    policy = AdminPolicy.new(nil, user: @regular_user)
    assert_not policy.manage?
  end

  test "anonymous user cannot manage admin area" do
    policy = AdminPolicy.new(nil, user: nil)
    assert_not policy.manage?
  end

  test "admin can access index (dashboard)" do
    policy = AdminPolicy.new(nil, user: @admin)
    assert policy.index?
  end

  test "regular user cannot access index" do
    policy = AdminPolicy.new(nil, user: @regular_user)
    assert_not policy.index?
  end

  test "anonymous user cannot access index" do
    policy = AdminPolicy.new(nil, user: nil)
    assert_not policy.index?
  end
end
