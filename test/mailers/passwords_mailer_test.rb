require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email is sent to user" do
    user = users(:one)
    email = PasswordsMailer.reset(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal "Reset your password", email.subject
    assert_equal [ user.email_address ], email.to
    # The token is encrypted in the email, so we just check that the email contains password reset content
    assert_match /password.*reset/i, email.body.encoded
  end

  test "reset email contains reset link" do
    user = users(:one)
    email = PasswordsMailer.reset(user)

    assert_match /password.*reset/i, email.body.encoded
    assert_match /passwords\/.*\/edit/i, email.body.encoded
    assert_match user.email_address, email.body.encoded
  end
end
