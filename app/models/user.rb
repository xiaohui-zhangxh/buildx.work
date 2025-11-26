class User < ApplicationRecord
  include HasRoles
  include AccountLocking
  include SessionManagement
  include PasswordManagement
  include EmailConfirmation

  has_secure_password

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }, allow_blank: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  validate :password_strength, if: -> { new_record? || !password.nil? }

  # Check if user can perform an action on a record
  # @param action [Symbol, String] The action to check (e.g., :update, :destroy)
  # @param record [Object, nil] The record to check permissions for (nil for collection actions)
  # @return [Boolean] true if user can perform the action, false otherwise
  def can?(action, record = nil)
    policy_class = ActionPolicy.lookup(record)
    policy = policy_class.new(record, user: self)
    policy.public_send("#{action}?")
  rescue ActionPolicy::Unauthorized, ActionPolicy::NotFound, NoMethodError
    false
  end

  private

    def password_strength
      return if password.blank?

      # At least 8 characters, including letters and numbers
      unless password.length >= 8 && password.match?(/[a-zA-Z]/) && password.match?(/\d/)
        errors.add(:password, "must be at least 8 characters and include both letters and numbers")
      end
    end
end
