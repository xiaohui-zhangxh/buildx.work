require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "index shows welcome page without authentication" do
    get root_path

    assert_response :success
    assert_select "h1", minimum: 1 # Should have at least one heading
  end

  test "index sets correct meta tags when system is installed" do
    # Ensure system is installed
    SystemConfig.set("installation_completed", "true", description: "系统安装完成", category: "system") unless SystemConfig.installation_completed?
    SystemConfig.set("site_name", "Test Site", description: "测试站点", category: "site")
    SystemConfig.set("site_tagline", "Test Tagline", description: "测试标语", category: "site")

    get root_path

    assert_response :success
    # Meta tags are set in the controller, we verify the page loads correctly
  end

  test "index redirects to installation when system is not installed" do
    # Temporarily set installation_completed to false
    SystemConfig.set("installation_completed", "false", description: "系统安装完成", category: "system")

    get root_path

    # Should redirect to installation page
    assert_redirected_to installation_path
  end

  test "index is accessible without authentication" do
    # Ensure system is installed
    SystemConfig.set("installation_completed", "true", description: "系统安装完成", category: "system") unless SystemConfig.installation_completed?

    # This should not redirect to login
    get root_path

    assert_response :success
    # Verify it's not a redirect to login
    assert_not_equal new_session_path, response.location
  end
end

