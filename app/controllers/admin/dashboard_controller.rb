module Admin
  class DashboardController < BaseController
    def index
      @user_count = User.count
      @role_count = Role.count
      @recent_users = User.order(created_at: :desc).limit(5)
    end
  end
end
