class RolePolicy < ApplicationPolicy
  # Only admins can list roles
  def index?
    user&.has_role?(:admin)
  end

  # Only admins can view roles
  def show?
    user&.has_role?(:admin)
  end

  # Only admins can create roles
  def create?
    user&.has_role?(:admin)
  end

  # Only admins can update roles
  def update?
    user&.has_role?(:admin)
  end

  # Only admins can delete roles
  def destroy?
    user&.has_role?(:admin)
  end

  # Only admins can manage roles (all actions)
  def manage?
    user&.has_role?(:admin)
  end
end
