module My
  class ProfileController < ApplicationController
    def show
      @user = Current.user
    end

    def edit
      @user = Current.user
    end

    def update
      @user = Current.user

      # Build update params - only include password if provided
      update_params = profile_params
      if update_params[:password].blank?
        update_params = update_params.except(:password, :password_confirmation)
      end

      if @user.update(update_params)
        redirect_to my_profile_path, notice: "Profile updated successfully!"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

      def profile_params
        params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
      end
  end
end
