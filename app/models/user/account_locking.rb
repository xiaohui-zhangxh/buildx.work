module User::AccountLocking
  extend ActiveSupport::Concern

  def locked?
    locked_at.present? && locked_at > 30.minutes.ago
  end

  def unlock!
    update(locked_at: nil, failed_login_attempts: 0)
  end
end
