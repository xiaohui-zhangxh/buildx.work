class Current < ActiveSupport::CurrentAttributes
  # Session record - unified data source for authentication
  # Warden stores Session ID, Current stores Session object for easy access
  attribute :session

  # Delegate user to session for convenience
  # Current.user is the unified way to access current user throughout the app
  delegate :user, to: :session, allow_nil: true, prefix: false
end
