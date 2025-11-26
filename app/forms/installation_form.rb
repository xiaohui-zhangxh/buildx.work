class InstallationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Site configuration
  attribute :site_name, :string
  attribute :site_description, :string
  attribute :time_zone, :string
  attribute :locale, :string

  # Admin account
  attribute :admin_email, :string
  attribute :admin_password, :string
  attribute :admin_password_confirmation, :string
  attribute :admin_name, :string

  validates :site_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :time_zone, presence: true
  validates :locale, presence: true, inclusion: { in: %w[zh-CN en] }
  validates :admin_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :admin_password, presence: true, length: { minimum: 8 }
  validates :admin_password_confirmation, presence: true
  validates :admin_name, presence: true, length: { minimum: 2, maximum: 100 }
  validate :password_match
  validate :password_strength
  validate :system_not_installed

  def save(request_host = nil)
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Create system configurations
      create_system_configs(request_host)

      # Create admin role
      create_admin_role

      # Create admin user and associate admin role
      admin_user = create_admin_user
      admin_user.add_role("admin")

      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  private

    def system_not_installed
      if SystemConfig.installation_completed?
        errors.add(:base, "系统已经安装，无法重复安装")
      end
    end

    def password_match
      return if admin_password.blank? || admin_password_confirmation.blank?

      if admin_password != admin_password_confirmation
        errors.add(:admin_password_confirmation, "密码不匹配")
      end
    end

    def password_strength
      return if admin_password.blank?

      unless admin_password.length >= 8 && admin_password.match?(/[a-zA-Z]/) && admin_password.match?(/\d/)
        errors.add(:admin_password, "密码必须至少 8 位，且包含字母和数字")
      end
    end

    def create_system_configs(request_host = nil)
      SystemConfig.set("site_name", site_name, description: "站点名称", category: "site")
      SystemConfig.set("site_description", site_description, description: "站点描述", category: "site") if site_description.present?
      SystemConfig.set("site_domain", request_host, description: "站点域名（生产环境，如：example.com，用于邮件链接和 hosts 验证）", category: "system") if request_host.present?

      # Convert Rails timezone name (e.g., "Beijing") to IANA timezone (e.g., "Asia/Shanghai")
      iana_timezone = convert_rails_to_iana_timezone(time_zone) || time_zone
      SystemConfig.set("time_zone", iana_timezone, description: "时区", category: "system")
      SystemConfig.set("locale", locale, description: "语言", category: "system")
      SystemConfig.set("installation_completed", "1", description: "安装完成标志", category: "system")
      SystemConfig.set("installation_completed_at", Time.current.iso8601, description: "安装完成时间", category: "system")
    end

    def convert_rails_to_iana_timezone(rails_timezone)
      return nil if rails_timezone.blank?

      # Find IANA timezone from Rails timezone name
      tz = ActiveSupport::TimeZone.all.find { |t| t.name == rails_timezone }
      tz&.tzinfo&.name
    end

    def create_admin_role
      Role.find_or_create_by!(name: "admin") do |role|
        role.description = "系统管理员，拥有所有权限"
      end
    end

    def create_admin_user
      user = User.create!(
        email_address: admin_email,
        password: admin_password,
        name: admin_name,
        confirmed_at: Time.current # First admin doesn't need email confirmation
      )

      user
    end
end
