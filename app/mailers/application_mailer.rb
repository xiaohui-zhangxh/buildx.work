class ApplicationMailer < ActionMailer::Base
  # Default from address is set in config/initializers/200_action_mailer.rb
  # from SystemConfig (mail_from_address and mail_from_name)
  default from: "from@example.com"
  layout "mailer"
end
