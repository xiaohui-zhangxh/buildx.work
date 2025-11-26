module Admin
  class UsersController < BaseController
    include AuditLogging

    before_action :set_user, only: [ :show, :edit, :update, :destroy ]

    def index
      @users = User.all
      @roles = Role.all # For role filter dropdown

      # Search by email or name
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @users = @users.where("email_address LIKE ? OR name LIKE ?", search_term, search_term)
      end

      # Filter by role
      if params[:role].present?
        @users = @users.joins(:roles).where(roles: { name: params[:role] }).distinct
      end

      @users = @users.order(created_at: :desc)
    end

    def show
    end

    def edit
    end

    def update
      update_params = user_params
      if update_params[:password].blank?
        update_params = update_params.except(:password, :password_confirmation)
      end

      if @user.update(update_params)
        redirect_to admin_user_path(@user), notice: "用户更新成功！"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      log_destroy(@user)
      @user.destroy
      redirect_to admin_users_path, notice: "用户已删除"
    end

    def batch_destroy
      user_ids = params[:user_ids] || []
      if user_ids.any?
        @users = User.where(id: user_ids)
        @users.destroy_all
        redirect_to admin_users_path, notice: "已删除 #{user_ids.size} 个用户"
      else
        redirect_to admin_users_path, alert: "请选择要删除的用户"
      end
    end

    def batch_assign_role
      user_ids = params[:user_ids] || []
      role_name = params[:role_name]
      if user_ids.any? && role_name.present?
        @users = User.where(id: user_ids)
        @users.each { |user| user.add_role(role_name) }
        redirect_to admin_users_path, notice: "已为 #{user_ids.size} 个用户分配角色 #{role_name}"
      else
        redirect_to admin_users_path, alert: "请选择用户并指定角色"
      end
    end

    def batch_remove_role
      user_ids = params[:user_ids] || []
      role_name = params[:role_name]
      if user_ids.any? && role_name.present?
        @users = User.where(id: user_ids)
        @users.each { |user| user.remove_role(role_name) }
        redirect_to admin_users_path, notice: "已移除 #{user_ids.size} 个用户的角色 #{role_name}"
      else
        redirect_to admin_users_path, alert: "请选择用户并指定角色"
      end
    end

    private

      def set_user
        @user = User.find(params[:id])
        authorize! @user, to: :manage?
      end

      def user_params
        params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
      end
  end
end
