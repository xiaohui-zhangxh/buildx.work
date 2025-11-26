# Base class for application policies
class ApplicationPolicy < ActionPolicy::Base
  # Configure additional authorization contexts here
  # (`user` is added by default).
  #
  #   authorize :account, optional: true
  #
  # Read more about authorization context: https://actionpolicy.evilmartians.io/#/authorization_context

  # Make user optional to allow anonymous access
  authorize :user, optional: true

  # Default user from Current.user if not provided in context
  def user
    authorization_context[:user] || Current.user
  end

  # Configure default rule
  # Default to deny all (minimum privilege principle)
  # Each policy should explicitly allow actions
  default_rule manage?: false

  private

  # Define shared methods useful for most policies.
  # For example:
  #
  #  def owner?
  #    record.user_id == user.id
  #  end
end
