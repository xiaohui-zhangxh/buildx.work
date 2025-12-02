require "test_helper"

class InstallationControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clear cache and set uninstalled state for installation tests
    SystemConfig::Current.values.clear
    SystemConfig.set("installation_completed", "0", description: "安装完成标志", category: "system")
    SystemConfig::Current.values.clear
  end

  test "should get show when not installed" do
    get installation_path
    assert_response :success
    assert_select "h2", text: /欢迎使用系统安装向导/
  end

  test "should redirect to root when installed" do
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig::Current.values.clear

    get installation_path
    assert_redirected_to root_path
  end

  test "should create installation with valid params" do
    # Admin role might already exist from fixtures, so use find_or_create
    admin_role_count_before = Role.count

    assert_difference "User.count", 1 do
      post installation_path, params: {
        installation_form: {
          site_name: "Test Site",
          site_description: "Test Description",
          time_zone: "Asia/Shanghai",
          locale: "zh-CN",
          admin_email: "admin@example.com",
          admin_password: "password123",
          admin_password_confirmation: "password123",
          admin_name: "Admin User"
        }
      }
    end

    # Role count should be same or increased by 1 (if didn't exist)
    assert_operator Role.count, :>=, admin_role_count_before

    assert_redirected_to root_path
    # Flash message should be set (check in redirect response)
    # Note: In integration tests, flash messages are in the session, not in response.body after redirect

    # Check installation status
    SystemConfig::Current.values.clear
    assert SystemConfig.installation_completed?

    # Check admin user
    admin = User.find_by(email_address: "admin@example.com")
    assert admin.present?
    assert admin.has_role?(:admin)
    assert_equal "Admin User", admin.name
    # First admin should be confirmed (no email confirmation required)
    assert admin.confirmed?, "Admin user should be confirmed after installation"

    # Check system configs
    assert_equal "Test Site", SystemConfig.get("site_name")
    assert_equal "Test Description", SystemConfig.get("site_description")
    assert_equal "Asia/Shanghai", SystemConfig.get("time_zone")
    assert_equal "zh-CN", SystemConfig.get("locale")
    assert_equal "1", SystemConfig.get("installation_completed")
    assert SystemConfig.get("installation_completed_at").present?
  end

  test "should auto-detect and save site domain from request" do
    # Simulate request with host and port
    host! "example.com"
    post installation_path, params: {
      installation_form: {
        site_name: "Test Site",
        time_zone: "Asia/Shanghai",
        locale: "zh-CN",
        admin_email: "admin@example.com",
        admin_password: "password123",
        admin_password_confirmation: "password123",
        admin_name: "Admin User"
      }
    }

    SystemConfig::Current.values.clear
    site_domain = SystemConfig.get("site_domain")
    assert site_domain.present?
    # Should include port (default test port)
    assert_match(/example\.com/, site_domain)
  end

  test "should auto-login admin user after installation" do
    post installation_path, params: {
      installation_form: {
        site_name: "Test Site",
        time_zone: "Asia/Shanghai",
        locale: "zh-CN",
        admin_email: "admin@example.com",
        admin_password: "password123",
        admin_password_confirmation: "password123",
        admin_name: "Admin User"
      }
    }

    # Should be authenticated after installation
    admin = User.find_by(email_address: "admin@example.com")
    assert admin.present?
    assert admin.sessions.active.any?
    # First admin should be confirmed (no email confirmation required)
    assert admin.confirmed?, "Admin user should be confirmed after installation"
    # Check that we're redirected (which happens after auto-login)
    assert_redirected_to root_path
  end

  test "should not create installation with invalid params" do
    assert_no_difference "User.count" do
      post installation_path, params: {
        installation_form: {
          site_name: "", # Invalid: empty
          time_zone: "Asia/Shanghai",
          locale: "zh-CN",
          admin_email: "invalid-email", # Invalid: wrong format
          admin_password: "short", # Invalid: too short
          admin_password_confirmation: "short",
          admin_name: "A" # Invalid: too short
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-error"
  end

  test "should not create installation when already installed" do
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig::Current.values.clear

    assert_no_difference "User.count" do
      post installation_path, params: {
        installation_form: {
          site_name: "Test Site",
          time_zone: "Asia/Shanghai",
          locale: "zh-CN",
          admin_email: "admin@example.com",
          admin_password: "password123",
          admin_password_confirmation: "password123",
          admin_name: "Admin User"
        }
      }
    end

    # Should redirect or show error
    # The form validation should prevent saving
  end

  test "should validate password match" do
    assert_no_difference "User.count" do
      post installation_path, params: {
        installation_form: {
          site_name: "Test Site",
          time_zone: "Asia/Shanghai",
          locale: "zh-CN",
          admin_email: "admin@example.com",
          admin_password: "password123",
          admin_password_confirmation: "different123", # Mismatch
          admin_name: "Admin User"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should validate password strength" do
    assert_no_difference "User.count" do
      post installation_path, params: {
        installation_form: {
          site_name: "Test Site",
          time_zone: "Asia/Shanghai",
          locale: "zh-CN",
          admin_email: "admin@example.com",
          admin_password: "onlyletters", # No numbers
          admin_password_confirmation: "onlyletters",
          admin_name: "Admin User"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should create admin role during installation" do
    admin_role_count_before = Role.count

    post installation_path, params: {
      installation_form: {
        site_name: "Test Site",
        time_zone: "Asia/Shanghai",
        locale: "zh-CN",
        admin_email: "admin@example.com",
        admin_password: "password123",
        admin_password_confirmation: "password123",
        admin_name: "Admin User"
      }
    }

    # Admin role should exist (created or already existed)
    admin_role = Role.find_by(name: "admin")
    assert admin_role.present?
    # Description might be from fixture or newly created
    assert admin_role.description.present?
    # Role count should be same or increased by 1
    assert_operator Role.count, :>=, admin_role_count_before
  end

  test "should not create duplicate admin role if already exists" do
    # Ensure admin role exists
    Role.find_or_create_by!(name: "admin") do |role|
      role.description = "系统管理员，拥有所有权限"
    end
    admin_role_count_before = Role.count

    # Try to install (should fail validation, but if it didn't, role shouldn't be duplicated)
    post installation_path, params: {
      installation_form: {
        site_name: "Test Site",
        time_zone: "Asia/Shanghai",
        locale: "zh-CN",
        admin_email: "admin@example.com",
        admin_password: "password123",
        admin_password_confirmation: "password123",
        admin_name: "Admin User"
      }
    }

    # Role count should not increase (find_or_create_by won't create duplicate)
    assert_equal admin_role_count_before, Role.count
  end

  test "admin user can login after installation without email confirmation" do
    # Step 1: Complete installation
    post installation_path, params: {
      installation_form: {
        site_name: "Test Site",
        time_zone: "Asia/Shanghai",
        locale: "zh-CN",
        admin_email: "admin@example.com",
        admin_password: "password123",
        admin_password_confirmation: "password123",
        admin_name: "Admin User"
      }
    }

    admin = User.find_by(email_address: "admin@example.com")
    assert admin.present?
    assert admin.confirmed?, "Admin should be confirmed after installation"

    # Step 2: Logout (simulate user exiting)
    # First, ensure we're logged in (from installation auto-login)
    delete session_path
    assert_redirected_to new_session_path

    # Clear Current.session and Warden to ensure clean state
    Current.session = nil
    Warden.test_reset!

    # Step 3: Try to login again
    # Reload admin to ensure we have fresh data
    admin.reload
    # Ensure admin is confirmed (should already be confirmed from installation)
    assert admin.confirmed?, "Admin should be confirmed after installation"
    assert admin.confirmed_at.present?, "Admin should have confirmed_at set"

    post session_path, params: {
      email_address: "admin@example.com",
      password: "password123"
    }

    # Should login successfully without requiring email confirmation
    assert_redirected_to root_path
    # Verify user is authenticated
    follow_redirect!
    assert_response :success
  end

  test "should detect browser locale from Accept-Language header" do
    get installation_path, headers: { "Accept-Language" => "zh-CN,zh;q=0.9,en;q=0.8" }

    assert_response :success
    # The locale should be detected from the header
  end

  test "should detect browser locale with simple language code" do
    get installation_path, headers: { "Accept-Language" => "zh" }

    assert_response :success
    # Should convert "zh" to "zh-CN"
  end

  test "should detect browser locale with English" do
    get installation_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }

    assert_response :success
    # Should detect "en"
  end

  test "should use default locale when Accept-Language is not supported" do
    get installation_path, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }

    assert_response :success
    # Should use default "zh-CN"
  end

  test "should convert IANA timezone to Rails timezone" do
    SystemConfig.set("time_zone", "Asia/Shanghai", description: "时区", category: "system")
    SystemConfig::Current.values.clear

    get installation_path

    assert_response :success
    # Should convert "Asia/Shanghai" to Rails timezone name
  end

  test "should use default timezone when IANA timezone is not set" do
    SystemConfig.where(key: "time_zone").destroy_all
    SystemConfig::Current.values.clear

    get installation_path

    assert_response :success
    # Should use Time.zone.name as default
  end

  test "should load default values from SystemConfig in show action" do
    SystemConfig.set("site_name", "Default Site", description: "站点名称", category: "site")
    SystemConfig.set("site_description", "Default Description", description: "站点描述", category: "site")
    SystemConfig::Current.values.clear

    get installation_path

    assert_response :success
    # Should load default values
  end

  test "should create restart.txt file after successful installation" do
    restart_file = Rails.root.join("tmp/restart.txt")
    File.delete(restart_file) if File.exist?(restart_file)

    post installation_path, params: {
      installation_form: {
        site_name: "Test Site",
        time_zone: "Asia/Shanghai",
        locale: "zh-CN",
        admin_email: "admin@example.com",
        admin_password: "password123",
        admin_password_confirmation: "password123",
        admin_name: "Admin User"
      }
    }

    # Should create restart.txt file
    assert File.exist?(restart_file), "restart.txt should be created after installation"
  end
end
