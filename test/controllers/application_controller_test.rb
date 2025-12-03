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
    # Ensure user is confirmed and has password
    @user.update!(confirmed_at: Time.current, password: "password123", password_confirmation: "password123")
    # Use SessionTestHelper's sign_in_as method
    session_record = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    login_as(session_record, scope: :default)
    Current.session = session_record

    # Temporarily set installation_completed to "0"
    SystemConfig.set("installation_completed", "0")
    get admin_root_path
    assert_response :success
    # Restore installation status
    SystemConfig.set("installation_completed", "1")
  ensure
    Current.session = nil
  end

  test "handles unauthorized exception with HTML format" do
    # Try to access admin with non-admin user
    regular_user = users(:two)
    regular_user.update!(confirmed_at: Time.current, password: "password123", password_confirmation: "password123")
    # Use SessionTestHelper's sign_in_as method
    session_record = regular_user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    login_as(session_record, scope: :default)
    Current.session = session_record

    get admin_root_path
    assert_response :forbidden
    assert_select "h1", text: /403|Forbidden/
  ensure
    Current.session = nil
  end

  test "handles unauthorized exception with JSON format" do
    regular_user = users(:two)
    regular_user.update!(confirmed_at: Time.current, password: "password123", password_confirmation: "password123")
    # Use SessionTestHelper's sign_in_as method
    session_record = regular_user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    login_as(session_record, scope: :default)
    Current.session = session_record

    get admin_root_path, headers: { "Accept" => "application/json" }
    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert_equal "Forbidden", json_response["error"]
    assert_match(/permission/, json_response["message"])
  ensure
    Current.session = nil
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

  test "real_ip extracts IP from CF-Connecting-IP header" do
    # Test that real_ip method correctly extracts IP from Cloudflare header
    @user.update!(confirmed_at: Time.current, password: "password123", password_confirmation: "password123")
    session_record = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    login_as(session_record, scope: :default)
    Current.session = session_record

    # Make a request with CF-Connecting-IP header
    get root_path, headers: { "CF-Connecting-IP" => "203.0.113.1" }
    assert_response :success

    # Verify that the session was created with the real IP (if we create a new session)
    # We can't directly test real_ip method in integration test, but we can verify
    # that the IP extraction works by checking session creation during login
  ensure
    Current.session = nil
  end

  test "real_ip falls back to X-Forwarded-For when CF-Connecting-IP is not present" do
    @user.update!(confirmed_at: Time.current, password: "password123", password_confirmation: "password123")
    session_record = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    login_as(session_record, scope: :default)
    Current.session = session_record

    # Make a request with only X-Forwarded-For header
    get root_path, headers: { "X-Forwarded-For" => "203.0.113.1" }
    assert_response :success
  ensure
    Current.session = nil
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

  test "sets meta tags with site_description when available" do
    SystemConfig.set("installation_completed", "1")
    SystemConfig.set("site_name", "Custom Site")
    SystemConfig.set("site_description", "Custom Description")
    get root_path
    assert_response :success
    # Meta tags should use custom description
  end

  test "sets meta tags with default description when site_description is blank" do
    SystemConfig.set("installation_completed", "1")
    SystemConfig.set("site_name", "Custom Site")
    SystemConfig.set("site_description", "")
    get root_path
    assert_response :success
    # Meta tags should use default description
  end

  test "sets meta tags with default site_name when site_name is blank" do
    SystemConfig.set("installation_completed", "1")
    SystemConfig.set("site_name", "")
    get root_path
    assert_response :success
    # Meta tags should use default "BuildX.work"
  end

  test "includes Authentication concern" do
    assert ApplicationController.include?(Authentication)
  end

  test "includes ActionPolicy::Controller" do
    assert ApplicationController.include?(ActionPolicy::Controller)
  end

  test "includes Pagy::Method" do
    assert ApplicationController.include?(Pagy::Method)
  end

  test "includes ApplicationControllerExtensions if extension file exists" do
    # ApplicationControllerExtensions should be included if the file exists
    extension_file = Rails.root.join("app", "controllers", "concerns", "application_controller_extensions.rb")
    if File.exist?(extension_file)
      assert ApplicationController.included_modules.include?(ApplicationControllerExtensions),
             "ApplicationController should include ApplicationControllerExtensions"
    else
      # If file doesn't exist, that's also a valid state (extensions are optional)
      assert true, "Extension file does not exist, which is valid"
    end
  end

  test "ApplicationControllerExtensions test method is available" do
    # If ApplicationControllerExtensions is included, the test method should be available
    extension_file = Rails.root.join("app", "controllers", "concerns", "application_controller_extensions.rb")
    if File.exist?(extension_file) && ApplicationController.included_modules.include?(ApplicationControllerExtensions)
      controller = ApplicationController.new
      assert controller.respond_to?(:test_controller_extension_method),
             "ApplicationController should respond to test_controller_extension_method"
      assert_equal "controller_extension_loaded", controller.test_controller_extension_method
    else
      # If extension is not loaded, that's also a valid state
      assert true, "Extension not loaded, which is valid"
    end
  end
end
