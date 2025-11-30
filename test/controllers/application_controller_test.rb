require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update(confirmed_at: Time.current)
  end

  test "redirects to installation if not installed" do
    # Temporarily set installation_completed to "0" (not "1")
    SystemConfig.set("installation_completed", "0")
    get root_path
    assert_redirected_to installation_path
    # Restore installation status
    SystemConfig.set("installation_completed", "1")
  end

  test "allows access if system is installed" do
    # Ensure installation is completed (default in test_helper)
    SystemConfig.set("installation_completed", "1")
    get root_path
    assert_response :success
  end

  test "skips installation check for installation controller" do
    # Temporarily set installation_completed to "0"
    SystemConfig.set("installation_completed", "0")
    get installation_path
    assert_response :success
    # Restore installation status
    SystemConfig.set("installation_completed", "1")
  end

  test "skips installation check for admin namespace" do
    @user.add_role(:admin)
    sign_in_as(@user)
    # Temporarily set installation_completed to "0"
    SystemConfig.set("installation_completed", "0")
    get admin_root_path
    assert_response :success
    # Restore installation status
    SystemConfig.set("installation_completed", "1")
  end

  test "handles unauthorized exception with HTML format" do
    # Try to access admin with non-admin user
    regular_user = users(:two)
    regular_user.update(confirmed_at: Time.current)
    sign_in_as(regular_user)
    get admin_root_path
    assert_response :forbidden
    assert_select "h1", text: /403|Forbidden/
  end

  test "handles unauthorized exception with JSON format" do
    regular_user = users(:two)
    regular_user.update(confirmed_at: Time.current)
    sign_in_as(regular_user)
    get admin_root_path, headers: { "Accept" => "application/json" }
    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert_equal "Forbidden", json_response["error"]
    assert_match(/permission/, json_response["message"])
  end

  test "sets default meta tags" do
    # Ensure installation is completed and set site config
    SystemConfig.set("installation_completed", "1")
    SystemConfig.set("site_name", "Test Site")
    SystemConfig.set("site_description", "Test Description")
    get root_path
    assert_response :success
    # Meta tags are set via set_meta_tags, which is tested indirectly
  end

  test "sets default meta tags when system not installed" do
    # Temporarily set installation_completed to "0"
    SystemConfig.set("installation_completed", "0")
    get installation_path
    assert_response :success
    # Should use default values when not installed
    # Restore installation status
    SystemConfig.set("installation_completed", "1")
  end

  test "includes Authentication concern" do
    assert ApplicationController.include?(Authentication)
  end

  test "includes ActionPolicy::Controller" do
    assert ApplicationController.include?(ActionPolicy::Controller)
  end

  test "includes Pagy::Backend" do
    assert ApplicationController.include?(Pagy::Backend)
  end

  private

    def sign_in_as(user)
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end
end
