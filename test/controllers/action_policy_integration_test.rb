require "test_helper"

class ActionPolicyIntegrationTest < ActionDispatch::IntegrationTest
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

  test "authorize! raises ActionPolicy::Unauthorized when user lacks permission" do
    sign_in_as(@regular_user)
    get admin_users_url
    assert_response :forbidden
  end

  test "authorize! allows access when user has permission" do
    sign_in_as(@admin)
    get admin_users_url
    assert_response :success
  end

  test "authorize! with record checks resource permission" do
    sign_in_as(@admin)
    get admin_user_url(@other_user)
    assert_response :success
  end

  test "authorize! with record denies access when user lacks resource permission" do
    sign_in_as(@regular_user)
    # Regular user should not access admin area
    get admin_user_url(@other_user)
    assert_response :forbidden
  end

  test "ActionPolicy::Unauthorized is rescued and returns 403" do
    sign_in_as(@regular_user)
    get admin_root_url
    assert_response :forbidden
    assert_match(/访问被拒绝|forbidden/i, response.body)
  end
end
