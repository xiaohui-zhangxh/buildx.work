module Admin
  class AuditLogsController < BaseController
    def index
      @audit_logs = AuditLog.includes(:user).recent

      # Search by user email or action
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @audit_logs = @audit_logs.joins(:user).where(
          "users.email_address LIKE ? OR audit_logs.action LIKE ? OR audit_logs.resource_type LIKE ?",
          search_term, search_term, search_term
        )
      end

      # Filter by action
      if params[:action_filter].present?
        @audit_logs = @audit_logs.by_action(params[:action_filter])
      end

      # Filter by resource type
      if params[:resource_type].present?
        @audit_logs = @audit_logs.by_resource(params[:resource_type])
      end

      # Filter by date range
      if params[:start_date].present?
        @audit_logs = @audit_logs.where("created_at >= ?", params[:start_date])
      end
      if params[:end_date].present?
        @audit_logs = @audit_logs.where("created_at <= ?", params[:end_date])
      end

      respond_to do |format|
        format.html
        format.csv { send_data generate_csv, filename: "audit_logs_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv" }
      end
    end

    def show
      @audit_log = AuditLog.find(params[:id])
    end

    private

      def generate_csv
        require "csv"

        CSV.generate(headers: true) do |csv|
          csv << [ "时间", "用户", "操作", "资源类型", "资源ID", "IP地址", "用户代理" ]

          @audit_logs.each do |log|
            csv << [
              log.created_at.strftime("%Y-%m-%d %H:%M:%S"),
              log.user.email_address,
              log.action,
              log.resource_type || "-",
              log.resource_id || "-",
              log.ip_address || "-",
              log.user_agent || "-"
            ]
          end
        end
      end
  end
end
