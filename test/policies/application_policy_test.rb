require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @policy = ApplicationPolicy.new(nil, user: @user)
  end

  test "should have user method" do
    assert_respond_to @policy, :user
  end

  test "user method returns user from context" do
    assert_equal @user, @policy.user
  end

  test "user method returns Current.user when context user is nil" do
    Current.session = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    policy = ApplicationPolicy.new(nil, user: nil)
    assert_equal @user, policy.user
  ensure
    Current.session = nil
  end

  test "default manage? rule returns false" do
    assert_not @policy.manage?
  end
end
