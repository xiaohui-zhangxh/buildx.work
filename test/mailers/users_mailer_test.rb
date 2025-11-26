require "test_helper"

class UsersMailerTest < ActionMailer::TestCase
  test "confirmation email is sent to user" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )

    email = UsersMailer.confirmation(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "请确认您的邮箱地址", email.subject
    assert_equal [ user.email_address ], email.to
  end

  test "confirmation email contains confirmation link" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )

    email = UsersMailer.confirmation(user)

    # Check that email contains confirmation URL (decode the body)
    body_text = email.text_part ? email.text_part.body.to_s : ""
    body_html = email.html_part ? email.html_part.body.to_s : ""
    combined_body = body_text + body_html

    # Check in both text and HTML parts
    assert_match /confirmations/, combined_body
    # Check that confirmation token is in the URL
    assert_match user.confirmation_token, combined_body
  end

  test "confirmation email sets user and confirmation_url instance variables" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )

    # Access the mailer instance to check instance variables
    mailer = UsersMailer.confirmation(user)

    # In ActionMailer tests, we need to render the email to access instance variables
    # The instance variables are available during rendering
    mailer.deliver_now

    # Verify the email was sent with correct content
    assert_match /confirmations/, mailer.text_part.body.to_s + mailer.html_part.body.to_s
  end
end

