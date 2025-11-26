class UserPolicy < ApplicationPolicy
  # Only admins can list all users
  def index?
    user&.has_role?(:admin)
  end

  # Admins can view any user, users can view themselves
  def show?
    user&.has_role?(:admin) || user == record
  end

  # Admins can create users, or allow registration
  def create?
    user&.has_role?(:admin) || !SystemConfig.installation_completed?
  end

  # Admins can update any user, users can update themselves
  def update?
    user&.has_role?(:admin) || user == record
  end

  # Only admins can delete users
  def destroy?
    user&.has_role?(:admin)
  end

  # Only admins can manage users (all actions)
  def manage?
    user&.has_role?(:admin)
  end
end
