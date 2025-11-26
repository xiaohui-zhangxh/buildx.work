module User::EmailConfirmation
  extend ActiveSupport::Concern

  included do
    # Generate confirmation token before create
    before_create :generate_confirmation_token, unless: :confirmed?
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    return true if confirmed?

    update_columns(
      confirmed_at: Time.current,
      confirmation_token: nil
    )
  end

  def send_confirmation_email
    return if confirmed?

    update_column(:confirmation_sent_at, Time.current)
    UsersMailer.confirmation(self).deliver_later
  end

  def confirmation_token_valid?(token)
    confirmation_token.present? && confirmation_token == token
  end

  def confirmation_token_expired?(expires_in: 24.hours)
    return true if confirmation_sent_at.nil?

    confirmation_sent_at < expires_in.ago
  end

  private

    def generate_confirmation_token
      self.confirmation_token = SecureRandom.urlsafe_base64(32)
    end
end
