class InstallationController < ApplicationController
  layout "authentication"
  allow_unauthenticated_access

  # Redirect to root if already installed
  before_action :redirect_if_installed

  def show
    @installation = InstallationForm.new

    # Load default values from SystemConfig (created by initializer)
    @installation.site_name = SystemConfig.get("site_name").presence
    @installation.site_description = SystemConfig.get("site_description").presence

    # Convert IANA timezone (e.g., "Asia/Shanghai") to Rails timezone name (e.g., "Beijing")
    iana_timezone = SystemConfig.get("time_zone").presence
    if iana_timezone.present?
      rails_timezone = convert_iana_to_rails_timezone(iana_timezone)
      @installation.time_zone = rails_timezone || Time.zone.name
    else
      @installation.time_zone = Time.zone.name
    end

    @installation.locale = SystemConfig.get("locale").presence || "zh-CN"

    # Auto-detect locale from browser Accept-Language header (override if detected)
    browser_locale = detect_browser_locale
    @installation.locale = browser_locale if browser_locale.present?

    # Timezone will be detected by JavaScript on the client side
  end

  def create
    @installation = InstallationForm.new(installation_params)

    if @installation.save(request.host_with_port)
      # Trigger Rails restart to reload configuration (e.g., mailer settings)
      # Puma watches tmp/restart.txt and will restart when this file is touched
      FileUtils.touch(Rails.root.join("tmp/restart.txt"))

      # Auto login admin user
      admin_user = User.find_by(email_address: @installation.admin_email)
      if admin_user
        session_record = admin_user.sign_in!(request.user_agent, request.remote_ip)
        warden.set_user(session_record)
      end

      redirect_to root_path, notice: "系统安装成功！欢迎使用。"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def redirect_if_installed
      redirect_to root_path if SystemConfig.installation_completed?
    end

    def installation_params
      params.require(:installation_form).permit(
        :site_name, :site_description, :time_zone, :locale,
        :admin_email, :admin_password, :admin_password_confirmation, :admin_name
      )
    end

    def convert_iana_to_rails_timezone(iana_timezone)
      # Find Rails timezone that matches the IANA timezone
      ActiveSupport::TimeZone.all.find { |tz| tz.tzinfo.name == iana_timezone }&.name
    end

    def detect_browser_locale
      # Parse Accept-Language header
      accept_language = request.headers["Accept-Language"]
      return nil if accept_language.blank?

      # Parse languages with quality values (e.g., "en-US,en;q=0.9,zh-CN;q=0.8")
      languages = accept_language.split(",").map do |lang|
        lang = lang.strip
        # Remove quality value if present (e.g., "en;q=0.9" -> "en")
        lang = lang.split(";").first.strip
        # Normalize format
        if lang.match?(/\A[a-z]{2}-[A-Z]{2}\z/i)
          lang
        elsif lang.match?(/\A[a-z]{2}\z/i)
          # Convert "en" to "en", "zh" to "zh-CN"
          case lang.downcase
          when "en"
            "en"
          when "zh"
            "zh-CN"
          else
            nil
          end
        else
          nil
        end
      end.compact

      # Find first supported locale
      supported_locales = %w[zh-CN en]
      languages.find { |lang| supported_locales.include?(lang) } ||
        (languages.any? { |lang| lang.start_with?("zh") } ? "zh-CN" : nil) ||
        (languages.any? { |lang| lang.start_with?("en") } ? "en" : nil) ||
        nil
    end
end
