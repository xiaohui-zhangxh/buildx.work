module My
  class SecurityController < ApplicationController
    def show
      @user = Current.user
    end

    def update
      @user = Current.user

      # Only allow password update for now
      if params[:user][:password].present?
        if @user.update(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
          # password_changed_at will be updated automatically via before_save callback
          redirect_to my_security_path, notice: "Password updated successfully!"
        else
          render :show, status: :unprocessable_entity
        end
      else
        redirect_to my_security_path, alert: "Password cannot be blank."
      end
    end
  end
end
