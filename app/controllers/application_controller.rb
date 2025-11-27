class ApplicationController < ActionController::Base
  include Authentication
  include ActionPolicy::Controller
  include Pagy::Backend

  # Check installation status before processing requests
  before_action :check_installation_status
  before_action :set_default_meta_tags

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Handle ActionPolicy::Unauthorized exceptions
  rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized

  private

    def check_installation_status
      # Skip check for installation controller and health check
      return if controller_name == "installation" || controller_name == "rails/health"

      # Skip check for admin namespace (admin controllers handle their own authentication)
      return if controller_path.start_with?("admin/")

      # If system is not installed, redirect to installation wizard
      redirect_to installation_path unless SystemConfig.installation_completed?
    end

    def handle_unauthorized(exception)
      respond_to do |format|
        format.html { render "errors/forbidden", status: :forbidden, layout: "application" }
        format.json { render json: { error: "Forbidden", message: "You don't have permission to perform this action." }, status: :forbidden }
      end
    end

    def set_default_meta_tags
      # 如果系统已安装，从 SystemConfig 读取配置；否则使用默认值
      if SystemConfig.installation_completed?
        site_name = SystemConfig.get("site_name").presence || "BuildX.work"
        site_description = SystemConfig.get("site_description").presence
      else
        # 安装页面使用默认值
        site_name = "BuildX.work"
        site_description = nil
      end

      # 如果没有站点描述，使用默认描述
      default_description = "集成认证授权、多租户、权限管理等企业级功能，内置精心调试的AI提示词，让您通过简单对话即可精准完成任务，专注于业务逻辑开发，快速启动新项目。"
      description = site_description || default_description

      set_meta_tags(
        site: site_name,
        title: site_name,
        description: description,
        keywords: "Ruby on Rails, Rails 8, 企业级应用, 认证授权, 多租户, 权限管理, Action Policy, Warden, Tailwind CSS, DaisyUI",
        reverse: true,
        separator: " | ",
        charset: "utf-8",
        viewport: "width=device-width,initial-scale=1"
      )
    end
end
