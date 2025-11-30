# Extension Loading Mechanism
#
# This initializer automatically loads extension modules from sub-projects
# that extend infrastructure functionality.
#
# Extension modules should be placed in:
# - app/models/concerns/*_extensions.rb (e.g., user_extensions.rb)
# - app/controllers/concerns/*_extensions.rb (e.g., application_controller_extensions.rb)
#
# The extension modules will be automatically included in the corresponding
# infrastructure classes.
#
# Example:
#   # app/models/concerns/user_extensions.rb
#   module UserExtensions
#     extend ActiveSupport::Concern
#     included do
#       has_many :workspaces, dependent: :destroy
#     end
#   end
#
# The UserExtensions module will be automatically included in the User model.

Rails.application.config.to_prepare do
  # Load User model extensions
  if defined?(User) && User < ApplicationRecord
    user_extensions_file = Rails.root.join("app", "models", "concerns", "user_extensions.rb")
    if File.exist?(user_extensions_file)
      require_dependency user_extensions_file.to_s
      if defined?(UserExtensions)
        User.class_eval do
          include UserExtensions unless included_modules.include?(UserExtensions)
        end
      end
    end
  end

  # Load ApplicationController extensions
  if defined?(ApplicationController) && ApplicationController < ActionController::Base
    app_controller_extensions_file = Rails.root.join("app", "controllers", "concerns", "application_controller_extensions.rb")
    if File.exist?(app_controller_extensions_file)
      require_dependency app_controller_extensions_file.to_s
      if defined?(ApplicationControllerExtensions)
        ApplicationController.class_eval do
          include ApplicationControllerExtensions unless included_modules.include?(ApplicationControllerExtensions)
        end
      end
    end
  end

  # Load ApplicationHelper extensions
  if defined?(ApplicationHelper)
    app_helper_extensions_file = Rails.root.join("app", "helpers", "application_helper_extensions.rb")
    if File.exist?(app_helper_extensions_file)
      require_dependency app_helper_extensions_file.to_s
      if defined?(ApplicationHelperExtensions)
        ApplicationHelper.class_eval do
          include ApplicationHelperExtensions unless included_modules.include?(ApplicationHelperExtensions)
        end
      end
    end
  end

  # Load Mailer extensions (if ActionMailer is available)
  if defined?(ActionMailer) && defined?(ApplicationMailer)
    mailer_extensions_file = Rails.root.join("app", "mailers", "concerns", "mailer_extensions.rb")
    if File.exist?(mailer_extensions_file)
      require_dependency mailer_extensions_file.to_s
      if defined?(MailerExtensions)
        ApplicationMailer.class_eval do
          include MailerExtensions unless included_modules.include?(MailerExtensions)
        end
      end
    end
  end
end
