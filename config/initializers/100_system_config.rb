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

  config_file = Rails.root.join("config", "system_configs.yml")
  configs = ActiveSupport::ConfigurationFile.parse(config_file).deep_symbolize_keys

  # 处理其他所有配置项
  configs.each do |category_name, category_configs|
    category_configs.each do |key, config|
      SystemConfig.ensure_config(key, default_value: config[:default_value], description: config[:description], category: category_name.to_s)
    end
  end

  SystemConfig.set("installation_completed", User.count.zero? ? "0" : "1", description: "安装完成标志", category: "system")
end
