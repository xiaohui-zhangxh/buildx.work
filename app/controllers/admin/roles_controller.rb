module Admin
  class RolesController < BaseController
    include AuditLogging

    before_action :set_role, only: [ :show, :edit, :update, :destroy ]

    def index
      @roles = Role.all

      # Search by name or description
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @roles = @roles.where("name LIKE ? OR description LIKE ?", search_term, search_term)
      end

      @roles = @roles.order(created_at: :desc)
    end

    def show
    end

    def new
      @role = Role.new
    end

    def create
      @role = Role.new(role_params)

      if @role.save
        redirect_to admin_role_path(@role), notice: "角色创建成功！"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @role.update(role_params)
        redirect_to admin_role_path(@role), notice: "角色更新成功！"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      log_destroy(@role)
      @role.destroy
      redirect_to admin_roles_path, notice: "角色已删除"
    end

    private

      def set_role
        @role = Role.find(params[:id])
        authorize! @role, to: :manage?
      end

      def role_params
        params.require(:role).permit(:name, :description)
      end
  end
end
