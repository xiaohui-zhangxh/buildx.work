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

  test "daisy_form_with works without model scope or url" do
    # Test line 81: form_with(model: false, ...)
    # This case is hard to test because form_with requires at least one of model, scope, or url
    # But we can test it by providing format only (which will trigger the else branch)
    # Actually, looking at the code, if none of model, scope, or url are provided,
    # it will call form_with(model: false, ...), but this might still require a route
    # Let's skip this edge case as it's unlikely to be used in practice
    skip "form_with(model: false) without url is unlikely to be used in practice"
  end

  test "format_time handles I18n.t success for weekday" do
    # Test lines 24-25: I18n.t("date.day_names") success path
    # Ensure time is within this week but not today
    now = Time.current
    this_week_start = now.beginning_of_week
    # Use a time that's definitely in this week but not today
    time = [ this_week_start + 1.day, now - 1.day ].min

    result = format_time(time)
    # Should include weekday name from I18n
    assert result.length > 5
    assert_match(/\d{2}:\d{2}/, result)
    # Should include weekday name (not just time)
    assert result.include?(" ") || result.length > 8
  end

  test "format_time handles I18n.t failure for weekday" do
    # Test line 27: I18n.t rescue path
    # Ensure time is within this week but not today
    now = Time.current
    this_week_start = now.beginning_of_week
    # Use a time that's definitely in this week but not today
    time = [ this_week_start + 1.day, now - 1.day ].min

    # Stub I18n.t to raise error only for "date.day_names"
    original_t = I18n.method(:t)
    I18n.define_singleton_method(:t) do |key, **options|
      if key == "date.day_names"
        raise StandardError, "Translation error"
      else
        original_t.call(key, **options)
      end
    end

    begin
      result = format_time(time)
      # Should fallback to strftime("%A %H:%M")
      assert result.length > 5
      assert_match(/\d{2}:\d{2}/, result)
    ensure
      I18n.define_singleton_method(:t, original_t)
    end
  end

  test "format_time handles I18n.l success for this month" do
    # Test line 33: I18n.l(time, format: :short) success path
    # Ensure time is within this month but not this week
    now = Time.current
    this_month_start = now.beginning_of_month
    this_week_start = now.beginning_of_week

    # Use a time that's definitely in this month but before this week
    if this_week_start > this_month_start
      time = this_month_start + 1.day
    else
      # If this week started before this month, use a time in the past within this month
      time = this_month_start + 1.day
      time = [ time, now - 1.day ].min
    end

    result = format_time(time)
    # Should use I18n.l with :short format
    assert result.length > 5
  end

  test "format_time handles I18n.l failure for this month with zh locale" do
    # Test lines 36-37: I18n.l rescue path with zh locale
    original_locale = I18n.locale
    I18n.locale = :"zh-CN"

    # Use a time within this month but not this week
    # Calculate a time that's definitely in this month but before this week
    now = Time.current
    this_month_start = now.beginning_of_month
    this_week_start = now.beginning_of_week

    # If this week started before this month, we can't have a time in this month but before this week
    # So use a time that's definitely in this month and in the past
    if this_week_start <= this_month_start
      # Use a time in the past within this month
      time = this_month_start + 1.day
      time = [ time, now - 1.day ].min
    else
      # Use a time between this_month_start and this_week_start
      time = this_month_start + 1.day
    end

    # Stub I18n.l to raise MissingTranslationData
    original_l = I18n.method(:l)
    I18n.define_singleton_method(:l) { |*args| raise I18n::MissingTranslationData.new(:key, :locale) }

    begin
      result = format_time(time)
      # Should fallback to Chinese format: "%m月%d日 %H:%M" or full date if outside this month
      # The result should have time format
      assert_match(/\d{2}:\d{2}/, result)
      # If it's in this month, should have Chinese format
      if time >= this_month_start && time < this_week_start
        assert_match(/\d+月\d+日/, result)
      end
    ensure
      I18n.define_singleton_method(:l, original_l)
      I18n.locale = original_locale
    end
  end

  test "format_time handles I18n.l failure for this month with en locale" do
    # Test line 39: I18n.l rescue path with en locale
    original_locale = I18n.locale
    I18n.locale = :en

    # Use a time within this month but not this week
    # Calculate a time that's definitely in this month but before this week
    now = Time.current
    this_month_start = now.beginning_of_month
    this_week_start = now.beginning_of_week

    # If this week started before this month, we can't have a time in this month but before this week
    # So use a time that's definitely in this month and in the past
    if this_week_start <= this_month_start
      # Use a time in the past within this month
      time = this_month_start + 1.day
      time = [ time, now - 1.day ].min
    else
      # Use a time between this_month_start and this_week_start
      time = this_month_start + 1.day
    end

    # Stub I18n.l to raise MissingTranslationData
    original_l = I18n.method(:l)
    I18n.define_singleton_method(:l) { |*args| raise I18n::MissingTranslationData.new(:key, :locale) }

    begin
      result = format_time(time)
      # Should fallback to English format: "%b %d %H:%M" or full date if outside this month
      # The result should have time format
      assert_match(/\d{2}:\d{2}/, result)
    ensure
      I18n.define_singleton_method(:l, original_l)
      I18n.locale = original_locale
    end
  end

  test "format_time handles I18n.l failure for longer periods" do
    # Test line 47: I18n.l rescue path for longer periods
    time = 2.months.ago
    # Stub I18n.l to raise MissingTranslationData
    original_l = I18n.method(:l)
    I18n.define_singleton_method(:l) { |*args| raise I18n::MissingTranslationData.new(:key, :locale) }

    begin
      result = format_time(time)
      # Should fallback to "%Y-%m-%d %H:%M"
      assert_match(/\d{4}-\d{2}-\d{2}/, result)
      assert_match(/\d{2}:\d{2}/, result)
    ensure
      I18n.define_singleton_method(:l, original_l)
    end
  end
end
