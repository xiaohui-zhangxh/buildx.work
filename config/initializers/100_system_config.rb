Rails.application.config.after_initialize do
  # Skip during database tasks (db:reset, db:migrate, db:drop, etc.)
  # Check command line arguments or rake tasks
  skip_db_tasks = false
  if defined?(Rake) && Rake.respond_to?(:application) && Rake.application.respond_to?(:top_level_tasks)
    skip_db_tasks = Rake.application.top_level_tasks.any? { |task| task.start_with?("db:") }
  elsif ARGV.any? { |arg| arg.start_with?("db:") }
    skip_db_tasks = true
  end

  next if skip_db_tasks

  # Only set default configs if the table exists (skip during migrations)
  next unless ActiveRecord::Base.connection.table_exists?("system_configs")

  # Set default configs
  # SystemConfig.set handles race conditions internally, so we can call it safely
  SystemConfig.set("installation_completed", User.count.zero? ? "0" : "1", description: "安装完成标志", category: "system")
  next if SystemConfig.installation_completed?

  SystemConfig.set("site_domain", "", description: "站点域名（生产环境，如：example.com，用于邮件链接和 hosts 验证）", category: "system")
  SystemConfig.set("site_name", "BuildX.work", description: "站点名称", category: "site")
  SystemConfig.set("site_description", "BuildX.work - 业务网站生成平台", description: "站点描述", category: "site")
  SystemConfig.set("time_zone", "Asia/Shanghai", description: "时区", category: "system")
  SystemConfig.set("locale", "zh-CN", description: "语言", category: "system")
  SystemConfig.set("password_expiration_days", 90, description: "密码过期天数", category: "system")

  # 邮件服务器配置（生产环境）
  SystemConfig.set("smtp_address", "", description: "SMTP 服务器地址", category: "mail") unless SystemConfig.exists?(key: "smtp_address")
  SystemConfig.set("smtp_port", "587", description: "SMTP 服务器端口", category: "mail") unless SystemConfig.exists?(key: "smtp_port")
  SystemConfig.set("smtp_domain", "", description: "SMTP 域名", category: "mail") unless SystemConfig.exists?(key: "smtp_domain")
  SystemConfig.set("smtp_user_name", "", description: "SMTP 用户名", category: "mail") unless SystemConfig.exists?(key: "smtp_user_name")
  SystemConfig.set("smtp_password", "", description: "SMTP 密码", category: "mail") unless SystemConfig.exists?(key: "smtp_password")
  SystemConfig.set("smtp_authentication", "plain", description: "SMTP 认证方式（plain, login, cram_md5）", category: "mail") unless SystemConfig.exists?(key: "smtp_authentication")
  SystemConfig.set("smtp_enable_starttls_auto", "true", description: "启用 STARTTLS 自动（true/false）", category: "mail") unless SystemConfig.exists?(key: "smtp_enable_starttls_auto")
  SystemConfig.set("mail_from_address", "noreply@example.com", description: "默认发件人地址", category: "mail") unless SystemConfig.exists?(key: "mail_from_address")
  SystemConfig.set("mail_from_name", "BuildX.work", description: "默认发件人名称", category: "mail") unless SystemConfig.exists?(key: "mail_from_name")
end
