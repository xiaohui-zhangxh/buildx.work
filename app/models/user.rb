class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }, allow_blank: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  validate :password_strength, if: -> { new_record? || !password.nil? }

  # Track password changes
  before_save :update_password_changed_at, if: :password_digest_changed?
  # Set initial password_changed_at for new users
  after_create :set_initial_password_changed_at, if: -> { password_changed_at.nil? }

  # Password expiration check (default: 90 days)
  PASSWORD_EXPIRATION_DAYS = 90

  # Get active sessions (for session management)
  def active_sessions
    sessions.active.order(created_at: :desc)
  end

  # Get all sessions including inactive ones (for audit)
  def all_sessions
    sessions.order(created_at: :desc)
  end

  # Account locking methods
  def locked?
    locked_at.present? && locked_at > 30.minutes.ago
  end

  def unlock!
    update(locked_at: nil, failed_login_attempts: 0)
  end

  def sign_in!(user_agent, ip_address)
    sessions.create!(user_agent: user_agent, ip_address: ip_address)
  end

  # Password expiration methods
  def password_expired?
    return false if password_changed_at.nil?

    password_changed_at < PASSWORD_EXPIRATION_DAYS.days.ago
  end

  def password_expires_soon?(days: 7)
    return false if password_changed_at.nil?

    password_changed_at < (PASSWORD_EXPIRATION_DAYS - days).days.ago
  end

  def days_since_password_change
    return nil if password_changed_at.nil?

    (Time.current - password_changed_at).to_i / 1.day
  end

  def days_until_password_expires
    return nil if password_changed_at.nil?

    days_passed = days_since_password_change
    [ PASSWORD_EXPIRATION_DAYS - days_passed, 0 ].max
  end

  private

    def update_password_changed_at
      self.password_changed_at = Time.current
    end

    def set_initial_password_changed_at
      update_column(:password_changed_at, created_at) if password_changed_at.nil?
    end

    def password_strength
      return if password.blank?

      # At least 8 characters, including letters and numbers
      unless password.length >= 8 && password.match?(/[a-zA-Z]/) && password.match?(/\d/)
        errors.add(:password, "must be at least 8 characters and include both letters and numbers")
      end
    end
end
