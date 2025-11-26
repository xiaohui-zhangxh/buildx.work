class UsersController < ApplicationController
  layout "authentication", only: %i[ new create ]
  allow_unauthenticated_access only: %i[ new create ]

  def new
    redirect_to root_path if authenticated?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # Send confirmation email
      @user.send_confirmation_email

      redirect_to new_session_path, notice: "注册成功！请检查您的邮箱并点击确认链接以激活账户。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @users = User.order(created_at: :desc)
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
    # Only allow users to edit their own profile
    redirect_to users_path, alert: "You can only edit your own profile." unless @user == Current.user
  end

  def update
    @user = User.find(params[:id])
    # Only allow users to update their own profile
    unless @user == Current.user
      redirect_to users_path, alert: "You can only edit your own profile."
      return
    end

    # Build update params - only include password if provided
    update_params = user_params
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to @user, notice: "Profile updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
    end
end
