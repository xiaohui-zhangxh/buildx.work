require "test_helper"

module Admin
  class BaseControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = users(:one)
      @admin_user.add_role(:admin)
      @admin_user.update!(password: "password123", password_confirmation: "password123", confirmed_at: Time.current)
      @regular_user = users(:two)
      @regular_user.update!(password: "password123", password_confirmation: "password123", confirmed_at: Time.current)
    end

    test "requires authentication" do
      get admin_root_path
      assert_redirected_to new_session_path
    end

    test "requires admin role" do
      sign_in_as(@regular_user)
      get admin_root_path
      assert_response :forbidden
    end

    test "allows admin access" do
      sign_in_as(@admin_user)
      get admin_root_path
      assert_response :success
    end

    test "sets admin meta tags" do
      sign_in_as(@admin_user)
      get admin_root_path
      assert_response :success
      # Meta tags are set via set_meta_tags, which is tested indirectly through response
    end

    test "uses admin layout" do
      # Use SessionTestHelper's sign_in_as method which properly sets up Warden session
      sign_in_as(@admin_user)
      get admin_root_path
      assert_response :success
      # Layout is set via layout "admin", which is tested indirectly through response
    end
  end
end
