require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  setup do
    # Ensure system is installed for tests
    SystemConfig.set("installation_completed", "1", description: "系统安装完成", category: "system") unless SystemConfig.installation_completed?
    SystemConfig::Current.values.clear
  end

  test "format_time returns empty string for nil" do
    assert_equal "", format_time(nil)
  end

  test "format_time formats time for today as time only" do
    time = Time.current
    result = format_time(time)
    assert_match(/\d{2}:\d{2}/, result)
    assert_no_match(/\d{4}-\d{2}-\d{2}/, result)
  end

  test "format_time formats time for this week with weekday" do
    time = 2.days.ago
    result = format_time(time)
    # Should include weekday and time
    assert result.length > 5
  end

  test "format_time formats time for this month with date" do
    time = 10.days.ago
    result = format_time(time)
    # Should include date information
    assert result.length > 5
  end

  test "format_time formats time for longer periods with full date" do
    time = 2.months.ago
    result = format_time(time)
    # Should include full date
    assert result.length > 10
  end

  test "site_name returns default when system not installed" do
    SystemConfig.set("installation_completed", "0", description: "系统安装完成", category: "system")
    SystemConfig::Current.values.clear
    assert_equal "BuildX.work", site_name
  end

  test "site_name returns config value when system installed" do
    SystemConfig.set("installation_completed", "1", description: "系统安装完成", category: "system")
    SystemConfig.set("site_name", "My Custom Site", description: "站点名称", category: "site")
    SystemConfig::Current.values.clear
    assert_equal "My Custom Site", site_name
  end

  test "site_name returns default when config value is blank" do
    SystemConfig.set("installation_completed", "1", description: "系统安装完成", category: "system")
    SystemConfig.set("site_name", "", description: "站点名称", category: "site")
    SystemConfig::Current.values.clear
    assert_equal "BuildX.work", site_name
  end

  test "daisy_form_with creates form with DaisyFormBuilder" do
    user = User.new
    form_html = daisy_form_with(model: user, url: "/test") do |form|
      form.text_field(:name)
    end
    assert_match(/<form/, form_html)
    assert_match(/name="user\[name\]"/, form_html)
  end

  test "daisy_form_with works with url parameter" do
    form_html = daisy_form_with(url: "/test") do |form|
      form.text_field(:email_address)
    end
    assert_match(/<form/, form_html)
    assert_match(/action="\/test"/, form_html)
  end

  test "daisy_form_with works with scope parameter" do
    form_html = daisy_form_with(scope: :session, url: "/sessions") do |form|
      form.text_field(:email_address)
    end
    assert_match(/<form/, form_html)
    assert_match(/name="session\[email_address\]"/, form_html)
  end
end

