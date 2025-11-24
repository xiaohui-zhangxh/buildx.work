module My
  class SessionsController < ApplicationController
    def index
      @sessions = Current.user.sessions.order(created_at: :desc)
      @active_sessions = @sessions.select(&:active?)
      @current_session = Current.session
    end

    def destroy
      session_id = params[:id].to_i
      if terminate_session_by_id(session_id)
        redirect_to my_sessions_path, notice: "Session terminated successfully."
      else
        redirect_to my_sessions_path, alert: "Failed to terminate session."
      end
    end

    def destroy_all_others
      current_session_id = Current.session&.id
      other_sessions = Current.user.active_sessions.where.not(id: current_session_id)

      terminated_count = 0
      other_sessions.each do |session|
        session.terminate!
        terminated_count += 1
      end

      if terminated_count > 0
        redirect_to my_sessions_path, notice: "Terminated #{terminated_count} session(s)."
      else
        redirect_to my_sessions_path, notice: "No other active sessions to terminate."
      end
    end
  end
end
