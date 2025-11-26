module User::HasRoles
  extend ActiveSupport::Concern

  included do
    has_many :user_roles, dependent: :destroy
    has_many :roles, through: :user_roles
  end

  def has_role?(role_name)
    roles.exists?(name: role_name.to_s)
  end

  def add_role(role_name)
    role = Role.find_or_create_by!(name: role_name.to_s)
    user_roles.find_or_create_by!(role: role)
  end

  def remove_role(role_name)
    role = Role.find_by(name: role_name.to_s)
    return unless role

    user_roles.where(role: role).destroy_all
  end
end
