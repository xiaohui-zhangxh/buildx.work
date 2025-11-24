require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new redirects to root if already authenticated" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)
    # After sign_in_as, we should be authenticated
    # Make another request to verify session persists
    get root_path
    # Now try to access new user path - should redirect
    get new_user_path
    assert_redirected_to root_path
  end

  test "new shows registration form if not authenticated" do
    get new_user_path
    assert_response :success
  end

  test "create with valid data creates user and signs in" do
    assert_difference "User.count", 1 do
      post users_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "New User"
        }
      }
    end

    assert_redirected_to root_path
    # After redirect, Current.user should be set by Warden callbacks
    # In test, we need to follow redirect to trigger callbacks
    follow_redirect!
    # Current.user is set by Warden callbacks after the request
    # We can verify by checking the session was created
    user = User.find_by(email_address: "newuser@example.com")
    assert user.present?
    assert user.sessions.active.any?
  end

  test "create with invalid email shows errors" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "invalid-email",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end

  test "create with weak password shows errors" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "test@example.com",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end

  test "create with password without numbers shows errors" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "test@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end

  test "create with password without letters shows errors" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "test@example.com",
          password: "12345678",
          password_confirmation: "12345678"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end

  test "create with duplicate email shows errors" do
    existing_user = users(:one)

    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: existing_user.email_address,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end

  test "create with mismatched passwords shows errors" do
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email_address: "test@example.com",
          password: "password123",
          password_confirmation: "password456"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end

  test "index requires authentication" do
    get users_path
    assert_redirected_to new_session_path
  end

  test "index shows list of users when authenticated" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)

    get users_path
    assert_response :success
    assert_select "h1", text: /users/i
  end

  test "show requires authentication" do
    user = users(:one)
    get user_path(user)
    assert_redirected_to new_session_path
  end

  test "show displays user details when authenticated" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)

    get user_path(user)
    assert_response :success
    assert_select "h1", text: /#{user.name}/i
  end

  test "edit requires authentication" do
    user = users(:one)
    get edit_user_path(user)
    assert_redirected_to new_session_path
  end

  test "edit shows form for own profile" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)

    get edit_user_path(user)
    assert_response :success
    assert_select "form"
  end

  test "edit redirects when trying to edit other user's profile" do
    user1 = users(:one)
    user1.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user1)

    user2 = User.create!(
      email_address: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Other User"
    )

    get edit_user_path(user2)
    assert_redirected_to users_path
    assert_equal "You can only edit your own profile.", flash[:alert]
  end

  test "update requires authentication" do
    user = users(:one)
    patch user_path(user), params: { user: { name: "New Name" } }
    assert_redirected_to new_session_path
  end

  test "update with valid data updates own profile" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)

    patch user_path(user), params: {
      user: {
        name: "Updated Name",
        email_address: user.email_address
      }
    }

    assert_redirected_to user_path(user)
    user.reload
    assert_equal "Updated Name", user.name
    assert_equal "Profile updated successfully!", flash[:notice]
  end

  test "update with invalid data shows errors" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)

    # Try to update with invalid email
    patch user_path(user), params: {
      user: {
        name: user.name,
        email_address: "invalid-email"
      }
    }

    assert_response :unprocessable_entity
    assert_select "div.alert-error"
  end

  test "update redirects when trying to update other user's profile" do
    user1 = users(:one)
    user1.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user1)

    user2 = User.create!(
      email_address: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Other User"
    )

    patch user_path(user2), params: {
      user: {
        name: "Hacked Name",
        email_address: user2.email_address
      }
    }

    assert_redirected_to users_path
    assert_equal "You can only edit your own profile.", flash[:alert]
    user2.reload
    assert_equal "Other User", user2.name # Should not be updated
  end

  test "update password when provided" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)

    old_digest = user.password_digest

    patch user_path(user), params: {
      user: {
        password: "newpass123",
        password_confirmation: "newpass123",
        email_address: user.email_address,
        name: user.name
      }
    }

    assert_redirected_to user_path(user)
    user.reload
    assert_not_equal old_digest, user.password_digest
  end

  test "update does not change password when not provided" do
    user = users(:one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in_as(user)

    old_digest = user.password_digest

    patch user_path(user), params: {
      user: {
        password: "",
        password_confirmation: "",
        email_address: user.email_address,
        name: "New Name"
      }
    }

    assert_redirected_to user_path(user)
    user.reload
    assert_equal old_digest, user.password_digest # Password should not change
    assert_equal "New Name", user.name
  end
end
