module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

    def current_user
      Current.user
    end

    def warden
      request.env["warden"]
    end

    # Terminate a specific session (for managing other device logins)
    # Session record is kept for audit purposes
    def terminate_session_by_id(session_id)
      return false unless Current.user

      session_record = Current.user.sessions.find_by(id: session_id)
      return false unless session_record
      return false if session_record.current? # Can't terminate current session this way

      session_record.terminate!
      true
    end

    def authenticated?
      !!resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      return Current.session if warden.authenticated?

      restore_user_from_remember_token

      Current.session
    end

    def restore_user_from_remember_token
      # If not authenticated via Warden, try remember_token cookie
      return unless cookies.signed[:remember_token]

      # Find session by remember_token
      session_record = Session.active.find_by(remember_token: cookies.signed[:remember_token])
      if session_record&.remember_token_valid?(cookies.signed[:remember_token])
        # Set session in Warden - after_set_user callback will automatically set Current.session
        warden.set_user(session_record)
      else
        # Invalid or expired token - clean up cookie and logout
        cookies.delete(:remember_token)
        warden.logout
      end
    end

    def remember_me!
      return unless Current.session

      Current.session.remember_me!
      cookies.signed.permanent[:remember_token] = { value: Current.session.remember_token, httponly: true, same_site: :lax }
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def terminate_session
      cookies.delete(:remember_token)
      warden.logout
    end
end
