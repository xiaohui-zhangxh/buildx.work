require "test_helper"

module My
  class ProfileControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @user.update!(password: "password123", password_confirmation: "password123")
    end

    test "show requires authentication" do
      get my_profile_path
      assert_redirected_to new_session_path
    end

    test "show displays profile when authenticated" do
      sign_in_as(@user)

      get my_profile_path
      assert_response :success
      assert_select "h1", text: /个人信息/
      assert_select "div", text: /#{@user.email_address}/
    end

    test "edit requires authentication" do
      get edit_my_profile_path
      assert_redirected_to new_session_path
    end

    test "edit displays form when authenticated" do
      sign_in_as(@user)

      get edit_my_profile_path
      assert_response :success
      assert_select "form"
      assert_select "input[name='user[name]']"
      assert_select "input[name='user[email_address]']"
      assert_select "input[name='user[password]']"
    end

    test "update requires authentication" do
      patch my_profile_path, params: {
        user: {
          name: "New Name",
          email_address: @user.email_address
        }
      }
      assert_redirected_to new_session_path
    end

    test "update with valid data updates profile" do
      sign_in_as(@user)

      patch my_profile_path, params: {
        user: {
          name: "New Name",
          email_address: "newemail@example.com"
        }
      }

      assert_redirected_to my_profile_path
      @user.reload
      assert_equal "New Name", @user.name
      assert_equal "newemail@example.com", @user.email_address
    end

    test "update with password updates password" do
      sign_in_as(@user)
      old_digest = @user.password_digest

      patch my_profile_path, params: {
        user: {
          name: @user.name,
          email_address: @user.email_address,
          password: "newpass123",
          password_confirmation: "newpass123"
        }
      }

      assert_redirected_to my_profile_path
      @user.reload
      assert_not_equal old_digest, @user.password_digest
    end

    test "update without password does not change password" do
      sign_in_as(@user)
      old_digest = @user.password_digest

      patch my_profile_path, params: {
        user: {
          name: "New Name",
          email_address: @user.email_address,
          password: "",
          password_confirmation: ""
        }
      }

      assert_redirected_to my_profile_path
      @user.reload
      assert_equal old_digest, @user.password_digest
      assert_equal "New Name", @user.name
    end

    test "update with invalid data shows errors" do
      sign_in_as(@user)

      patch my_profile_path, params: {
        user: {
          name: @user.name,
          email_address: "invalid-email"
        }
      }

      assert_response :unprocessable_entity
      assert_select ".alert-error"
    end

    test "update with weak password shows errors" do
      sign_in_as(@user)

      patch my_profile_path, params: {
        user: {
          name: @user.name,
          email_address: @user.email_address,
          password: "weak",
          password_confirmation: "weak"
        }
      }

      assert_response :unprocessable_entity
      assert_select ".alert-error"
    end
  end
end
