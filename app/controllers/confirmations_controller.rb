class ConfirmationsController < ApplicationController
  layout "authentication"
  allow_unauthenticated_access

  def show
    token = params[:token]
    return redirect_to new_session_path, alert: "确认链接无效。" if token.blank?

    user = User.find_by(confirmation_token: token)
    return redirect_to new_session_path, alert: "确认链接无效或已过期。" if user.nil?

    if user.confirmed?
      redirect_to new_session_path, notice: "您的邮箱已经确认过了。"
      return
    end

    if user.confirmation_token_expired?
      redirect_to new_session_path, alert: "确认链接已过期，请重新注册或联系管理员。"
      return
    end

    if user.confirm!
      # Create session and authenticate user after confirmation
      session_record = user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      )
      warden.set_user(session_record)

      redirect_to root_path, notice: "邮箱确认成功！欢迎使用！"
    else
      redirect_to new_session_path, alert: "确认失败，请重试。"
    end
  end
end
