class Users::ProfilesController < ApplicationController
  include UserScoped

  before_action :ensure_current_user, only: %i[ edit update ]

  def show
  end

  def edit
  end

  def update
    @user.update!(user_params)
    redirect_to users_url
  end

  private
    def user_params
      params.require(:user).permit(:name, :email_address, :password)
    end
end
