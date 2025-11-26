module User::PasswordManagement
  extend ActiveSupport::Concern

  included do
    # Track password changes
    before_save :update_password_changed_at, if: :password_digest_changed?
    # Set initial password_changed_at for new users
    after_create :set_initial_password_changed_at, if: -> { password_changed_at.nil? }
  end

  # Get password expiration days from SystemConfig (default: 90 days)
  def password_expiration_days
    SystemConfig.get("password_expiration_days")&.to_i || 90
  end

  def password_expired?
    return false if password_changed_at.nil?

    password_changed_at < password_expiration_days.days.ago
  end

  def password_expires_soon?(days: 7)
    return false if password_changed_at.nil?

    password_changed_at < (password_expiration_days - days).days.ago
  end

  def days_since_password_change
    return nil if password_changed_at.nil?

    (Time.current - password_changed_at).to_i / 1.day
  end

  def days_until_password_expires
    return nil if password_changed_at.nil?

    days_passed = days_since_password_change
    [ password_expiration_days - days_passed, 0 ].max
  end

  private

    def update_password_changed_at
      self.password_changed_at = Time.current
    end

    def set_initial_password_changed_at
      update_column(:password_changed_at, created_at) if password_changed_at.nil?
    end
end
