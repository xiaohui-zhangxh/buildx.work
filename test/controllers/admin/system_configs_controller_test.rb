require "test_helper"

module Admin
  class SystemConfigsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @admin = users(:one)
      @admin.add_role("admin") unless @admin.has_role?("admin")
      @admin.update!(password: "password123", password_confirmation: "password123")

      @regular_user = users(:two)
      @regular_user.update!(password: "password123", password_confirmation: "password123")

      @config = SystemConfig.find_or_create_by!(key: "test_config") do |c|
        c.value = "test_value"
        c.description = "Test config"
        c.category = "test"
      end
    end

    test "should redirect to login if not authenticated" do
      get admin_system_configs_url
      assert_redirected_to new_session_path
    end

    test "should return 403 if not admin" do
      sign_in_as(@regular_user)
      get admin_system_configs_url
      assert_response :forbidden
    end

    test "should show system configs index for admin" do
      sign_in_as(@admin)
      get admin_system_configs_url
      assert_response :success
      assert_select "h1", text: "系统配置"
    end

    test "should show edit system config form for admin" do
      sign_in_as(@admin)
      get edit_admin_system_config_url(@config)
      assert_response :success
      assert_select "form"
    end

    test "should update system config for admin" do
      sign_in_as(@admin)
      patch admin_system_config_url(@config), params: {
        system_config: {
          value: "updated_value",
          description: "Updated description"
        }
      }
      assert_redirected_to admin_system_configs_path
      @config.reload
      assert_equal "updated_value", @config.value
      assert_equal "Updated description", @config.description
    end

    test "should update system config with empty value" do
      sign_in_as(@admin)
      # SystemConfig allows empty value, so this should succeed
      patch admin_system_config_url(@config), params: {
        system_config: {
          value: "",
          description: "Updated description"
        }
      }
      assert_redirected_to admin_system_configs_path
      @config.reload
      assert_equal "", @config.value
      assert_equal "Updated description", @config.description
    end

    test "should not show installation_completed in index" do
      sign_in_as(@admin)
      # Ensure installation_completed exists
      SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
      get admin_system_configs_url
      assert_response :success
      # Should not contain installation_completed in the response
      assert_select "code.badge", text: "installation_completed", count: 0
    end

    test "should redirect when trying to edit installation_completed" do
      sign_in_as(@admin)
      installation_config = SystemConfig.find_or_create_by!(key: "installation_completed") do |c|
        c.value = "1"
        c.description = "安装完成标志"
        c.category = "system"
      end
      get edit_admin_system_config_url(installation_config)
      assert_redirected_to admin_system_configs_path
      assert_equal "该配置项不允许编辑", flash[:alert]
    end

    test "should redirect when trying to update installation_completed" do
      sign_in_as(@admin)
      installation_config = SystemConfig.find_or_create_by!(key: "installation_completed") do |c|
        c.value = "1"
        c.description = "安装完成标志"
        c.category = "system"
      end
      original_value = installation_config.value
      patch admin_system_config_url(installation_config), params: {
        system_config: {
          value: "0",
          description: "Updated description"
        }
      }
      assert_redirected_to admin_system_configs_path
      assert_equal "该配置项不允许修改", flash[:alert]
      # Value should not be changed
      installation_config.reload
      assert_equal original_value, installation_config.value
    end
  end
end
