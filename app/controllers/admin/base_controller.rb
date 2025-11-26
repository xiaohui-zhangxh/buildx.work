module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_authentication
    before_action :authorize_admin_access
    before_action :set_admin_meta_tags

    private

      def authorize_admin_access
        policy = AdminPolicy.new(nil, user: current_user)
        unless policy.dashboard?
          raise ActionPolicy::Unauthorized.new(policy, :dashboard?)
        end
      end

      def set_admin_meta_tags
        set_meta_tags(
          title: "管理后台",
          description: "BuildX.work 管理后台 - 用户管理、角色管理、权限管理、系统配置",
          keywords: "管理后台, 用户管理, 角色管理, 权限管理, 系统配置"
        )
      end
  end
end
