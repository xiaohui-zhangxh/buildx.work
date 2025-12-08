# DeploymentVersion
#
# Manages deployment version information for cache invalidation.
# The version is generated during Docker build and stored in config/version.txt.
#
# Usage:
#   DeploymentVersion.current  # => "abc123" or "20241208120000"
#
class DeploymentVersion
  VERSION_FILE = Rails.root.join("config", "version.txt").freeze

  class << self
    # Get current deployment version
    # Returns the version string from config/version.txt, or "dev" in development
    def current
      @current ||= begin
        if File.exist?(VERSION_FILE)
          File.read(VERSION_FILE).strip.presence || "unknown"
        elsif Rails.env.development? || Rails.env.test?
          "dev"
        else
          "unknown"
        end
      end
    end

    # Reset cached version (useful for testing)
    def reset!
      @current = nil
    end
  end
end

