class UsersMailer < ApplicationMailer
  def confirmation(user)
    @user = user
    @confirmation_url = confirmation_url(user.confirmation_token)
    mail subject: "请确认您的邮箱地址", to: user.email_address
  end
end
