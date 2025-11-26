module Admin
  class PoliciesController < BaseController
    def index
      @policies = [
        { name: "UserPolicy", description: "用户资源权限策略" },
        { name: "RolePolicy", description: "角色资源权限策略" },
        { name: "AdminPolicy", description: "管理后台权限策略" }
      ]
    end

    def show
      policy_name = params[:id]
      @policy = case policy_name
      when "UserPolicy"
                  {
                    name: "UserPolicy",
                    description: "用户资源权限策略",
                    rules: [
                      { action: "index?", description: "只有管理员可以查看用户列表" },
                      { action: "show?", description: "管理员可以查看任何用户，普通用户只能查看自己" },
                      { action: "create?", description: "管理员可以创建用户，或系统未安装时允许注册" },
                      { action: "update?", description: "管理员可以更新任何用户，普通用户只能更新自己" },
                      { action: "destroy?", description: "只有管理员可以删除用户" },
                      { action: "manage?", description: "只有管理员可以管理用户（所有操作）" }
                    ]
                  }
      when "RolePolicy"
                  {
                    name: "RolePolicy",
                    description: "角色资源权限策略",
                    rules: [
                      { action: "index?", description: "只有管理员可以查看角色列表" },
                      { action: "show?", description: "只有管理员可以查看角色详情" },
                      { action: "create?", description: "只有管理员可以创建角色" },
                      { action: "update?", description: "只有管理员可以更新角色" },
                      { action: "destroy?", description: "只有管理员可以删除角色" },
                      { action: "manage?", description: "只有管理员可以管理角色（所有操作）" }
                    ]
                  }
      when "AdminPolicy"
                  {
                    name: "AdminPolicy",
                    description: "管理后台权限策略",
                    rules: [
                      { action: "dashboard?", description: "只有管理员可以访问管理后台仪表盘" },
                      { action: "manage?", description: "只有管理员可以访问管理后台（所有操作）" }
                    ]
                  }
      else
                  nil
      end

      redirect_to admin_policies_path, alert: "权限策略不存在" unless @policy
    end
  end
end
