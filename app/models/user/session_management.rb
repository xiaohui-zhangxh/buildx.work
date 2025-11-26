module User::SessionManagement
  extend ActiveSupport::Concern

  included do
    has_many :sessions, dependent: :destroy
  end

  def active_sessions
    sessions.active.order(created_at: :desc)
  end

  def all_sessions
    sessions.order(created_at: :desc)
  end

  def sign_in!(user_agent, ip_address)
    sessions.create!(user_agent: user_agent, ip_address: ip_address, last_activity_at: Time.current)
  end
end
