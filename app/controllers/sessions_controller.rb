class SessionsController < ApplicationController
  layout "authentication", only: %i[ new create ]
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    # Normalize email address (same as User model normalization)
    email = params[:email_address]&.strip&.downcase
    password = params[:password]

    # Find user by email address
    user = User.find_by(email_address: email)

    # Check if account is locked
    if user&.locked?
      redirect_to new_session_path, alert: "Your account is locked. Please try again later."
      return
    end

    # Authenticate user
    if user && user.authenticate(password)
      # Authentication successful - reset failed login attempts
      user.update!(failed_login_attempts: 0, locked_at: nil)

      # Create session record
      session_record = user.sign_in!(request.user_agent, request.remote_ip)

      # Set user in Warden (using session record)
      # Warden callbacks will automatically set Current.session
      warden.set_user(session_record)

      # Handle "remember me" option
      remember_me! if params[:remember_me] == "1"

      redirect_to after_authentication_url
    else
      # Authentication failed
      if user
        # Increment failed login attempts
        new_attempts = user.failed_login_attempts + 1
        locked_at = nil

        # Lock account after 5 failed attempts
        if new_attempts >= 5
          locked_at = Time.current
        end

        user.update!(failed_login_attempts: new_attempts, locked_at: locked_at)

        # Show appropriate error message
        if locked_at
          redirect_to new_session_path, alert: "Your account has been locked due to too many failed login attempts. Please try again later."
        else
          redirect_to new_session_path, alert: "Invalid email address or password."
        end
      else
        # User not found - don't reveal that email doesn't exist (security best practice)
        redirect_to new_session_path, alert: "Invalid email address or password."
      end
    end
  end

  def destroy
    # Call terminate_session to handle Warden logout and cookies
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
