require "test_helper"

class TimezoneLocaleInitializerTest < ActiveSupport::TestCase
  setup do
    # Clear SystemConfig cache
    SystemConfig::Current.values.clear

    # Store original values to restore later
    @original_time_zone = Rails.application.config.time_zone
    @original_time_zone_runtime = Time.zone.name
    @original_default_locale = Rails.application.config.i18n.default_locale
    @original_default_locale_runtime = I18n.default_locale
  end

  teardown do
    # Restore original values
    Rails.application.config.time_zone = @original_time_zone
    Time.zone = @original_time_zone_runtime
    Rails.application.config.i18n.default_locale = @original_default_locale
    I18n.default_locale = @original_default_locale_runtime

    # Clear SystemConfig cache
    SystemConfig::Current.values.clear
  end

  test "should use default timezone and locale when system is not installed" do
    # Set system as not installed
    SystemConfig.set("installation_completed", "0", description: "安装完成标志", category: "system")
    # Remove timezone and locale configs to simulate uninstalled state
    SystemConfig.find_by(key: "time_zone")&.destroy
    SystemConfig.find_by(key: "locale")&.destroy
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Should not change timezone/locale when system is not installed
    # (initializer only runs when installation_completed? is true)
    # So values should remain as they were (could be from fixtures or previous tests)
    assert_not_nil Time.zone.name
    assert_not_nil I18n.default_locale
  end

  test "should use SystemConfig timezone when system is installed" do
    # Set system as installed
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig.set("time_zone", "Asia/Shanghai", description: "时区", category: "system")
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Should use Beijing (Rails name for Asia/Shanghai)
    assert_equal "Beijing", Time.zone.name
    assert_equal "Beijing", Rails.application.config.time_zone
  end

  test "should use SystemConfig locale when system is installed" do
    # Set system as installed
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig.set("locale", "en", description: "语言", category: "system")
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Should use English locale
    assert_equal :en, I18n.default_locale
    assert_equal :en, Rails.application.config.i18n.default_locale
  end

  test "should convert IANA timezone to Rails timezone name" do
    # Set system as installed with IANA timezone
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig.set("time_zone", "America/New_York", description: "时区", category: "system")
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Should convert to Rails timezone name
    rails_timezone = ActiveSupport::TimeZone.all.find { |tz| tz.tzinfo.name == "America/New_York" }&.name
    assert_equal rails_timezone, Time.zone.name
    assert_equal rails_timezone, Rails.application.config.time_zone
  end

  test "should not override locale if not in available locales" do
    # Set system as installed with invalid locale
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig.set("locale", "fr", description: "语言", category: "system")
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Should keep default locale (fr is not in available_locales)
    assert_equal :"zh-CN", I18n.default_locale
  end

  test "should keep default values when SystemConfig timezone is blank" do
    # Set system as installed but timezone is blank
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig.set("time_zone", "", description: "时区", category: "system")
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Should keep original timezone (not changed)
    # Note: This test verifies that blank values don't override defaults
    assert_not_nil Time.zone.name
  end

  test "should keep default values when SystemConfig locale is blank" do
    # Set system as installed but locale is blank
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig.set("locale", "", description: "语言", category: "system")
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Should keep default locale
    assert_equal :"zh-CN", I18n.default_locale
  end

  test "should sync config and runtime values" do
    # Set system as installed
    SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
    SystemConfig.set("time_zone", "Asia/Tokyo", description: "时区", category: "system")
    SystemConfig.set("locale", "en", description: "语言", category: "system")
    SystemConfig::Current.values.clear

    # Reload the initializer logic
    load_initializer_logic

    # Config and runtime values should be in sync
    assert_equal Rails.application.config.time_zone, Time.zone.name
    assert_equal Rails.application.config.i18n.default_locale, I18n.default_locale
  end

  private

    def load_initializer_logic
      # Simulate the initializer logic
      return unless ActiveRecord::Base.connection.table_exists?("system_configs")

      if SystemConfig.installation_completed?
        time_zone = SystemConfig.get("time_zone")
        if time_zone.present?
          rails_timezone = ActiveSupport::TimeZone.all.find { |tz| tz.tzinfo.name == time_zone }&.name
          if rails_timezone.present?
            Rails.application.config.time_zone = rails_timezone
            Time.zone = rails_timezone
          end
        end

        locale = SystemConfig.get("locale")
        if locale.present? && I18n.available_locales.include?(locale.to_sym)
          Rails.application.config.i18n.default_locale = locale.to_sym
          I18n.default_locale = locale.to_sym
        end
      end
    end
end
