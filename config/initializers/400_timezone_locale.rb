Rails.application.config.after_initialize do
  # Only configure if the table exists (skip during migrations)
  next unless ActiveRecord::Base.connection.table_exists?("system_configs")

  # Set timezone from SystemConfig (only if system is installed and config exists)
  if SystemConfig.installation_completed?
    time_zone = SystemConfig.get("time_zone")
    if time_zone.present?
      # Convert IANA timezone (e.g., "Asia/Shanghai") to Rails timezone name (e.g., "Beijing")
      rails_timezone = ActiveSupport::TimeZone.all.find { |tz| tz.tzinfo.name == time_zone }&.name
      if rails_timezone.present?
        # Use config.time_zone instead of Time.zone to avoid conflicts
        Rails.application.config.time_zone = rails_timezone
        # Also set Time.zone for immediate effect
        Time.zone = rails_timezone
      end
    end

    # Set default locale from SystemConfig (only if system is installed and config exists)
    locale = SystemConfig.get("locale")
    if locale.present? && I18n.available_locales.include?(locale.to_sym)
      # Use config.i18n.default_locale instead of I18n.default_locale to avoid conflicts
      Rails.application.config.i18n.default_locale = locale.to_sym
      # Also set I18n.default_locale for immediate effect
      I18n.default_locale = locale.to_sym
    end
  end
end
