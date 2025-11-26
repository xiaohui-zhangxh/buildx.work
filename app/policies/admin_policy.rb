class AdminPolicy < ApplicationPolicy
  # Only admins can access admin dashboard
  def dashboard?
    user&.has_role?(:admin)
  end

  # Only admins can access admin area (all actions)
  def manage?
    user&.has_role?(:admin)
  end

  # Allow dashboard action on :admin symbol
  def index?
    dashboard?
  end
end
