require "test_helper"

module My
  class SecurityControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @user.update!(password: "password123", password_confirmation: "password123")
    end

    test "show requires authentication" do
      get my_security_path
      assert_redirected_to new_session_path
    end

    test "show displays security settings when authenticated" do
      sign_in_as(@user)

      get my_security_path
      assert_response :success
      assert_select "h1", text: /安全设置/
    end

    test "show displays password status when password_changed_at is present" do
      @user.update!(password_changed_at: 30.days.ago)
      sign_in_as(@user)

      get my_security_path
      assert_response :success
      assert_select ".card-title", text: /密码状态/
      assert_select "div", text: /上次修改密码/
    end

    test "show displays account status" do
      sign_in_as(@user)

      get my_security_path
      assert_response :success
      assert_select ".card-title", text: /账户状态/
      assert_select "div", text: /账户锁定状态/
      assert_select "div", text: /登录失败次数/
    end

    test "update requires authentication" do
      patch my_security_path, params: {
        user: {
          password: "newpass123",
          password_confirmation: "newpass123"
        }
      }
      assert_redirected_to new_session_path
    end

    test "update with valid password updates password" do
      sign_in_as(@user)
      old_digest = @user.password_digest
      old_changed_at = @user.password_changed_at

      patch my_security_path, params: {
        user: {
          password: "newpass123",
          password_confirmation: "newpass123"
        }
      }

      assert_redirected_to my_security_path
      @user.reload
      assert_not_equal old_digest, @user.password_digest
      assert_not_equal old_changed_at, @user.password_changed_at
      assert_not_nil @user.password_changed_at
    end

    test "update with blank password redirects with alert" do
      sign_in_as(@user)

      patch my_security_path, params: {
        user: {
          password: "",
          password_confirmation: ""
        }
      }

      assert_redirected_to my_security_path
      assert_equal "Password cannot be blank.", flash[:alert]
    end

    test "update with invalid password shows errors" do
      sign_in_as(@user)

      patch my_security_path, params: {
        user: {
          password: "weak",
          password_confirmation: "weak"
        }
      }

      assert_response :unprocessable_entity
      # Check that the form was rendered (indicates validation failed)
      # The form should exist when validation fails
      assert_select "form"
    end

    test "update with non-matching passwords shows errors" do
      sign_in_as(@user)

      patch my_security_path, params: {
        user: {
          password: "newpass123",
          password_confirmation: "different123"
        }
      }

      assert_response :unprocessable_entity
      # Check that the form was rendered (indicates validation failed)
      # The form should exist when validation fails
      assert_select "form"
    end
  end
end
