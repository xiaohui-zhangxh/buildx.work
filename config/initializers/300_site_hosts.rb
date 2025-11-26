Rails.application.config.after_initialize do
  # Only configure hosts if the table exists (skip during migrations)
  next unless ActiveRecord::Base.connection.table_exists?("system_configs")

  # Configure hosts validation from SystemConfig in production
  if Rails.env.production?
    site_domain = SystemConfig.get("site_domain")

    if site_domain.present?
      # Extract host without port for hosts validation (Rails hosts config doesn't include port)
      host = site_domain.split(":").first

      # Skip localhost and IP addresses (Rails allows these by default in development)
      unless host == "localhost" || host == "127.0.0.1" || host.match?(/\A\d+\.\d+\.\d+\.\d+\z/)
        # Build allowed hosts list
        # Include the main domain and all subdomains
        allowed_hosts = [
          host,
          /.*\.#{Regexp.escape(host)}/
        ]

        # Set hosts configuration
        Rails.application.config.hosts = allowed_hosts

        # Skip DNS rebinding protection for the default health check endpoint
        Rails.application.config.host_authorization = {
          exclude: ->(request) { request.path == "/up" }
        }
      end
    end
  end
end
