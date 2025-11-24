# Load Warden strategies
Dir[Rails.root.join("lib/warden/strategies/**/*.rb")].each { |f| require f }

# Warden configuration for authentication management
# See: https://github.com/wardencommunity/warden
#
# Warden stores Session record instead of User directly
# This allows multi-device/multi-location login management
# Users can view and manage all active sessions

Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = ->(env) do
    # Return a redirect response that will be handled by the controller
    # The controller's rescue block will catch Warden::NotAuthenticated
    # and redirect appropriately
    request = ActionDispatch::Request.new(env)
    message = env["warden.options"][:message] || "Invalid email address or password."
    request.flash[:alert] = message
    [ 302, { "Location" => "/session/new" }, [] ]
  end
end

# Warden callbacks - must be defined on Warden::Manager class, not manager instance
# After Warden sets user (Session record), update Current.session
# This ensures Current.session is always in sync with Warden
# This callback is called whenever Warden sets a user (login, session restore, etc.)
Warden::Manager.after_set_user do |session_record, auth, opts|
  # session_record is the Session object stored in Warden
  if session_record.is_a?(Session)
    # Check if session is still active
    if session_record.active?
      Current.session = session_record
    else
      # Session was terminated, logout from Warden
      auth.logout
      Current.session = nil
      throw(:warden, message: "Session is logged out from another device")
    end
  end
end

Warden::Manager.after_authentication do |session_record, auth, opts|
  # 可以记录 session 的最后活动时间
  # TODO: 如果需要记录最后活动时间，可以在这里更新 session 的 updated_at
  # session_record.touch if session_record.is_a?(Session)
end

# After Warden fetches user from session, update Current.session
# This handles session restoration on each request
Warden::Manager.after_fetch do |session_record, auth, opts|
  if session_record.is_a?(Session)
    if session_record.active?
      Current.session = session_record
    else
      auth.logout
      Current.session = nil
    end
  end
end

# After logout, clear Current.session
Warden::Manager.before_logout do |session_record, auth, opts|
  session_record.terminate!
  Current.session = nil
end

# Serialize Session record ID into Warden session
Warden::Manager.serialize_into_session do |session|
  session.id
end

# Deserialize Session record from Warden session
# Only return active sessions (inactive sessions are terminated but kept for audit)
Warden::Manager.serialize_from_session do |id|
  Session.active.find_by(id: id)
end
