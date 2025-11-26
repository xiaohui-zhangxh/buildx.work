class AuditLog < ApplicationRecord
  belongs_to :user

  validates :action, presence: true

  # Serialize changes_data as JSON
  serialize :changes_data, coder: JSON

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_resource, ->(resource_type, resource_id = nil) {
    scope = where(resource_type: resource_type)
    scope = scope.where(resource_id: resource_id) if resource_id
    scope
  }
  scope :by_user, ->(user) { where(user: user) }

  # Create an audit log entry
  def self.log(user:, action:, resource: nil, changes: nil, request: nil, controller_name: nil, action_name: nil)
    create!(
      user: user,
      action: action.to_s,
      controller_name: controller_name,
      action_name: action_name,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      changes_data: changes,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  end
end
