module AuditLogging
  extend ActiveSupport::Concern

  included do
    # Only register callbacks for actions that exist in the controller
    # This avoids "missing callback actions" errors in Rails 7.1+
    after_action :log_action, if: -> { current_user.present? && should_log_action? }
  end

  private

    def log_destroy(resource)
      # Log before destruction
      return unless current_user && resource

      changes = resource.attributes.except("id", "created_at", "updated_at", "password_digest")
      AuditLog.log(
        user: current_user,
        action: "destroy",
        resource: resource,
        changes: changes,
        request: request,
        controller_name: controller_name,
        action_name: action_name
      )
    rescue StandardError => e
      # Silently fail logging to avoid breaking the main action
      Rails.logger.error "Failed to log destroy audit: #{e.message}"
    end

    def should_log_action?
      # Only log actions that exist in the controller and are in the list
      [ :create, :update, :batch_destroy, :batch_assign_role, :batch_remove_role ].include?(action_name.to_sym) &&
        self.class.action_methods.include?(action_name.to_s)
    end

    def log_action
      return unless current_user
      # Only log successful actions (including redirects which are successful responses)
      return unless response.successful? || response.redirect?
      return unless should_log_action?

      logged_action = action_name_for_logging
      resource = resource_for_logging
      changes = changes_for_logging

      AuditLog.log(
        user: current_user,
        action: logged_action,
        resource: resource,
        changes: changes,
        request: request,
        controller_name: controller_name,
        action_name: action_name
      )
    rescue StandardError => e
      # Silently fail logging to avoid breaking the main action
      Rails.logger.error "Failed to log audit: #{e.message}"
    end

    def action_name_for_logging
      case action_name
      when "create"
        "create"
      when "update"
        "update"
      when "destroy"
        "destroy"
      when "batch_destroy"
        "batch_destroy"
      when "batch_assign_role"
        "batch_assign_role"
      when "batch_remove_role"
        "batch_remove_role"
      else
        action_name
      end
    end

    def resource_for_logging
      # Try to find resource from instance variables
      @user || @role || @system_config || @resource
    end

    def changes_for_logging
      case action_name
      when "create"
        # For create, log all attributes
        return nil unless resource_for_logging
        resource_for_logging.attributes.except("id", "created_at", "updated_at", "password_digest")
      when "update"
        # For update, log only changed attributes
        return nil unless resource_for_logging
        if resource_for_logging.previous_changes.any?
          resource_for_logging.previous_changes.except("updated_at", "password_digest")
        else
          nil
        end
      when "destroy"
        # For destroy, log the resource attributes before deletion
        return nil unless resource_for_logging
        resource_for_logging.attributes.except("id", "created_at", "updated_at", "password_digest")
      when "batch_destroy", "batch_assign_role", "batch_remove_role"
        # For batch operations, log the parameters
        {
          user_ids: params[:user_ids],
          role_name: params[:role_name],
          count: params[:user_ids]&.size || 0
        }
      else
        nil
      end
    end
end
