Rails.application.config.after_initialize do
  # Only configure mailer if the table exists (skip during migrations)
  next unless ActiveRecord::Base.connection.table_exists?("system_configs")

  # Configure SMTP settings from SystemConfig in production
  # Note: We set directly to ActionMailer::Base because configuration from
  # Rails.application.config.action_mailer is already loaded via ActiveSupport.on_load(:action_mailer)
  # Setting in after_initialize ensures we can read from database after initial config is loaded
  # We use ApplicationMailer.smtp_settings_from_db to get settings, which is also called
  # in before_action to allow dynamic updates without restarting Rails
  if Rails.env.production?
    smtp_settings = ApplicationMailer.smtp_settings_from_db
    if smtp_settings
      ActionMailer::Base.delivery_method = :smtp
      ActionMailer::Base.smtp_settings = smtp_settings
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.raise_delivery_errors = true
    end
  end

  # Set default from address from SystemConfig
  from_address = ApplicationMailer.default_from_address
  if from_address != "from@example.com" || SystemConfig.get("mail_from_address").present?
    ActionMailer::Base.default from: from_address
  end

  # Set default_url_options from SystemConfig (for all environments)
  # Set directly to ActionMailer::Base to override initial config
  # We use ApplicationMailer.default_url_options_from_db to get settings, which is also called
  # in before_action to allow dynamic updates without restarting Rails
  url_options = ApplicationMailer.default_url_options_from_db
  if url_options
    ActionMailer::Base.default_url_options = url_options
  end
end
