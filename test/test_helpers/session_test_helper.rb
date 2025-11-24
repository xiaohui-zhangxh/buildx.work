module SessionTestHelper
  # Sign in a user using Warden test helpers
  # This creates a Session record and sets it in Warden
  # According to Warden test docs: https://github.com/wardencommunity/warden/wiki/Testing
  def sign_in_as(user)
    # Ensure user has correct password
    user.update!(password: "password123", password_confirmation: "password123") unless user.password_digest.present?

    # Create a Session record for the user
    user_agent = respond_to?(:request) && request ? request.user_agent : "Test"
    ip_address = respond_to?(:request) && request ? request.remote_ip : "127.0.0.1"

    session_record = user.sessions.create!(
      user_agent: user_agent,
      ip_address: ip_address,
      active: true
    )

    # Use Warden test helper to login with the Session record
    # Warden stores Session objects, not User objects
    # This properly sets up Warden session for integration tests
    login_as(session_record, scope: :default)

    # Set Current.session for consistency (Warden callbacks should handle this, but be safe)
    Current.session = session_record
  end

  def sign_out
    logout
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
