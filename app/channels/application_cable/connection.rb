module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      restore_session_from_warden || restore_session_from_remember_token || reject_unauthorized_connection
    end

    private
      # Restore session from Warden (stored in Rails session)
      # ActionCable connections don't go through Warden middleware automatically
      def restore_session_from_warden
        # Get Warden proxy from request environment
        warden = request.env["warden"]
        return false unless warden

        # Try to authenticate/fetch from Warden session
        # This will trigger Warden's serialize_from_session and after_fetch callbacks
        return false unless warden.authenticated?

        session_record = warden.user
        return false unless session_record.is_a?(Session) && session_record.active?

        # Warden's after_fetch callback will set Current.session
        # But we need to ensure it's set here for ActionCable
        Current.session = session_record
        self.current_user = Current.user
        true
      end

      # Restore session from remember_token cookie
      # This handles cases where user selected "remember me" but Warden session expired
      def restore_session_from_remember_token
        return false unless cookies.signed[:remember_token]

        # Find session by remember_token
        session_record = Session.active.find_by(remember_token: cookies.signed[:remember_token])
        return false unless session_record&.remember_token_valid?(cookies.signed[:remember_token])

        # Set session in Warden - after_set_user callback will automatically set Current.session
        warden = request.env["warden"]
        return false unless warden

        warden.set_user(session_record)
        # Ensure Current.session is set (Warden callback should handle this, but be safe)
        Current.session = session_record
        self.current_user = Current.user
        true
      end
  end
end
