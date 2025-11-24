module My
  class DashboardController < ApplicationController
    def show
      @user = Current.user
      @recent_sessions = @user.active_sessions.limit(5)
      @total_sessions = @user.sessions.count
      @active_sessions_count = @user.active_sessions.count
    end
  end
end
