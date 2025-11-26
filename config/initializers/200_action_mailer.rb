Rails.application.config.after_initialize do
  # Only configure mailer if the table exists (skip during migrations)
  next unless ActiveRecord::Base.connection.table_exists?("system_configs")

  # Configure SMTP settings from SystemConfig in production
  if Rails.env.production?
    smtp_address = SystemConfig.get("smtp_address")
    smtp_port = SystemConfig.get("smtp_port")
    smtp_domain = SystemConfig.get("smtp_domain")
    smtp_user_name = SystemConfig.get("smtp_user_name")
    smtp_password = SystemConfig.get("smtp_password")
    smtp_authentication = SystemConfig.get("smtp_authentication")
    smtp_enable_starttls_auto = SystemConfig.get("smtp_enable_starttls_auto")

    # Only configure SMTP if address is set
    if smtp_address.present?
      smtp_settings = {
        address: smtp_address,
        port: smtp_port&.to_i || 587,
        domain: smtp_domain.presence,
        user_name: smtp_user_name.presence,
        password: smtp_password.presence,
        authentication: (smtp_authentication&.to_sym || :plain),
        enable_starttls_auto: smtp_enable_starttls_auto != "false"
      }.compact

      Rails.application.config.action_mailer.delivery_method = :smtp
      Rails.application.config.action_mailer.smtp_settings = smtp_settings
      Rails.application.config.action_mailer.perform_deliveries = true
      Rails.application.config.action_mailer.raise_delivery_errors = true
    end
  end

  # Set default from address from SystemConfig
  mail_from_address = SystemConfig.get("mail_from_address")
  mail_from_name = SystemConfig.get("mail_from_name")

  if mail_from_address.present?
    from_address = if mail_from_name.present?
      "#{mail_from_name} <#{mail_from_address}>"
    else
      mail_from_address
    end

    ActionMailer::Base.default from: from_address
  end

  # Set default_url_options from SystemConfig (for all environments)
  # This ensures mail links use the correct host and port from installation
  site_domain = SystemConfig.get("site_domain")
  if site_domain.present?
    # Parse host and port from site_domain
    if site_domain.include?(":")
      host, port = site_domain.split(":")
      url_options = { host: host }
      url_options[:port] = port.to_i if port.present? && port.to_i > 0
      Rails.application.config.action_mailer.default_url_options = url_options
    else
      Rails.application.config.action_mailer.default_url_options = { host: site_domain }
    end
  end
end
