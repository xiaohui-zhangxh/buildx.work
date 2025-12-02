class ApplicationMailer < ActionMailer::Base
  # Dynamically configure mailer settings from SystemConfig
  # This ensures the configuration is read from database each time a mail is sent
  # Allows updating mail server config without restarting Rails
  before_action :update_mailer_settings

  # Use proc to dynamically read from address from database
  default from: -> { ApplicationMailer.default_from_address }

  layout "mailer"

  # Get SMTP settings from database
  # Returns nil if not configured or not in production
  def self.smtp_settings_from_db
    return nil unless Rails.env.production?
    return nil unless ActiveRecord::Base.connection.table_exists?("system_configs")

    smtp_address = SystemConfig.get("smtp_address")
    return nil unless smtp_address.present?

    smtp_port = SystemConfig.get("smtp_port")
    smtp_domain = SystemConfig.get("smtp_domain")
    smtp_user_name = SystemConfig.get("smtp_user_name")
    smtp_password = SystemConfig.get("smtp_password")
    smtp_authentication = SystemConfig.get("smtp_authentication")
    smtp_ssl = SystemConfig.get("smtp_ssl")

    {
      address: smtp_address,
      port: smtp_port&.to_i || 465,
      domain: smtp_domain.presence,
      user_name: smtp_user_name.presence,
      password: smtp_password.presence,
      authentication: (smtp_authentication&.to_sym || :plain),
      ssl: smtp_ssl == "true"
    }.compact
  end

  # Get default_url_options from database
  def self.default_url_options_from_db
    return nil unless ActiveRecord::Base.connection.table_exists?("system_configs")

    site_domain = SystemConfig.get("site_domain")
    return nil unless site_domain.present?

    if site_domain.include?(":")
      host, port = site_domain.split(":")
      url_options = { host: host }
      url_options[:port] = port.to_i if port.present? && port.to_i > 0
      url_options
    else
      { host: site_domain }
    end
  end

  # Get default from address from database
  def self.default_from_address
    # Only set if SystemConfig table exists (skip during migrations)
    return "from@example.com" unless ActiveRecord::Base.connection.table_exists?("system_configs")

    mail_from_address = SystemConfig.get("mail_from_address")
    mail_from_name = SystemConfig.get("mail_from_name")

    if mail_from_address.present?
      if mail_from_name.present?
        "#{mail_from_name} <#{mail_from_address}>"
      else
        mail_from_address
      end
    else
      # Fallback to default if not configured
      "from@example.com"
    end
  end

  private

    # Update mailer settings from database before sending each email
    # This allows updating mail server config without restarting Rails
    def update_mailer_settings
      return unless ActiveRecord::Base.connection.table_exists?("system_configs")

      # Update SMTP settings if configured in database
      if Rails.env.production?
        smtp_settings = self.class.smtp_settings_from_db
        if smtp_settings
          ActionMailer::Base.delivery_method = :smtp
          ActionMailer::Base.smtp_settings = smtp_settings
          ActionMailer::Base.perform_deliveries = true
          ActionMailer::Base.raise_delivery_errors = true
        end
      end

      # Update default_url_options if configured in database
      url_options = self.class.default_url_options_from_db
      if url_options
        ActionMailer::Base.default_url_options = url_options
      end
    end
end
