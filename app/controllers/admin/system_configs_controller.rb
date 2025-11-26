module Admin
  class SystemConfigsController < BaseController
    include AuditLogging

    before_action :set_system_config, only: [ :edit, :update ]

    def index
      # 排除 installation_completed 配置项，不在管理后台显示
      configs = SystemConfig.where.not(key: "installation_completed").order(:category, :key)
      @configs_by_category = configs.group_by(&:category)
    end

    def edit
      # 阻止编辑 installation_completed 配置项
      if @system_config.key == "installation_completed"
        redirect_to admin_system_configs_path, alert: "该配置项不允许编辑"
      end
    end

    def update
      # 阻止更新 installation_completed 配置项
      if @system_config.key == "installation_completed"
        redirect_to admin_system_configs_path, alert: "该配置项不允许修改"
        return
      end

      if @system_config.update(system_config_params)
        redirect_to admin_system_configs_path, notice: "配置更新成功！"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

      def set_system_config
        @system_config = SystemConfig.find(params[:id])
      end

      def system_config_params
        params.require(:system_config).permit(:value, :description)
      end
  end
end
