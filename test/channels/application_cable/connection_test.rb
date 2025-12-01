require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  setup do
    @user = users(:one)
    @user.update!(password: "password123", password_confirmation: "password123")
  end

  test "connects with valid Warden session" do
    # Create a session for the user
    session = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )

    # Create a simple Warden mock with closure to access session
    session_id = session.id
    warden = Object.new
    def warden.authenticated?
      true
    end
    warden.define_singleton_method(:user) do
      Session.active.find_by(id: session_id)
    end

    # Use ActionCable::Connection::TestCase's connect method
    # We need to stub the request environment before connecting
    # ActionCable::Connection uses request.env, which we can access after connection
    # For now, we'll test by creating the connection manually with stubbed environment
    server = ActionCable.server
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = warden

    # Create connection using ActionCable's internal API
    connection = ApplicationCable::Connection.new(server, env)

    # Connect should succeed
    assert_nothing_raised do
      connection.connect
    end

    assert_equal @user, connection.current_user
  end

  test "connects with remember_token cookie" do
    # Test lines 37, 38, 41, 42, 44, 46, 47, 48: restore_session_from_remember_token
    # Create a session with remember_token
    session = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true
    )
    session.remember_me!
    assert_not_nil session.remember_token

    # Create a Warden mock (not authenticated initially, but will be set after restore)
    warden = Object.new
    def warden.authenticated?
      false
    end
    def warden.set_user(session_record)
      # After set_user, we should set Current.session
      Current.session = session_record
      true
    end

    # Set up environment
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = warden

    # Create connection and stub cookies.signed to return the remember_token
    connection = ApplicationCable::Connection.new(ActionCable.server, env)

    # Stub cookies.signed[:remember_token] to return the token
    cookies_mock = Object.new
    def cookies_mock.signed
      self
    end
    cookies_mock.define_singleton_method(:[]) do |key|
      key == :remember_token ? session.remember_token : nil
    end

    # Stub the connection's cookies method
    connection.define_singleton_method(:cookies) { cookies_mock }

    # Connect should succeed
    assert_nothing_raised do
      connection.connect
    end

    # Verify user is authenticated
    assert_equal @user, connection.current_user
    assert_not_nil Current.session
    assert_equal session.id, Current.session.id
  ensure
    Current.session = nil
  end

  test "rejects connection without authentication" do
    # Create a Warden mock (not authenticated)
    warden = Object.new
    def warden.authenticated?
      false
    end

    # Set up environment
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = warden

    connection = ApplicationCable::Connection.new(ActionCable.server, env)

    # Connect should reject
    assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) do
      connection.connect
    end
  end

  test "rejects connection with invalid remember_token" do
    # Create a Warden mock (not authenticated)
    warden = Object.new
    def warden.authenticated?
      false
    end

    # Set up environment with invalid remember_token cookie
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = warden
    cookie_value = Rails.application.message_verifier(:signed).generate("invalid_token")
    env["HTTP_COOKIE"] = "remember_token=#{cookie_value}"

    connection = ApplicationCable::Connection.new(ActionCable.server, env)

    # Connect should reject (invalid token won't find a session)
    assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) do
      connection.connect
    end
  end

  test "rejects connection with expired remember_token" do
    # Create a session with expired remember_token
    session = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: true,
      remember_token: "expired_token",
      remember_created_at: 3.weeks.ago
    )

    # Create a Warden mock (not authenticated)
    warden = Object.new
    def warden.authenticated?
      false
    end

    # Set up environment with expired remember_token cookie
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = warden
    cookie_value = Rails.application.message_verifier(:signed).generate("expired_token")
    env["HTTP_COOKIE"] = "remember_token=#{cookie_value}"

    connection = ApplicationCable::Connection.new(ActionCable.server, env)

    # Connect should reject (expired token)
    assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) do
      connection.connect
    end
  end

  test "rejects connection with inactive session" do
    # Create an inactive session
    session = @user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1",
      active: false
    )

    # Create a Warden mock returning inactive session
    session_id = session.id
    warden = Object.new
    def warden.authenticated?
      true
    end
    warden.define_singleton_method(:user) do
      Session.find_by(id: session_id)
    end

    # Set up environment
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = warden

    connection = ApplicationCable::Connection.new(ActionCable.server, env)

    # Connect should reject
    assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) do
      connection.connect
    end
  end

  test "rejects connection when Warden returns non-Session object" do
    # Create a Warden mock returning User instead of Session
    warden = Object.new
    def warden.authenticated?
      true
    end
    def warden.user
      User.first
    end

    # Set up environment
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = warden

    connection = ApplicationCable::Connection.new(ActionCable.server, env)

    # Connect should reject
    assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) do
      connection.connect
    end
  end

  test "rejects connection when Warden is nil" do
    # No Warden in environment
    env = Rack::MockRequest.env_for("/cable")
    env["warden"] = nil

    connection = ApplicationCable::Connection.new(ActionCable.server, env)

    # Connect should reject
    assert_raises(ActionCable::Connection::Authorization::UnauthorizedError) do
      connection.connect
    end
  end
end
