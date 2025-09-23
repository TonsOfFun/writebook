class UsersController < ApplicationController
  require_unauthenticated_access only: %i[ new create ]

  before_action :verify_join_code, only: %i[ new create ]
  before_action :ensure_can_administer, only: %i[ update destroy ]
  before_action :set_user, only: %i[ update destroy ]


  def index
    @users = User.active
  end

  def new
    @user = User.new
  end

  def create
    @user = User.create!(user_params)
    start_new_session_for @user
    redirect_to root_url
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_session_url(email_address: user_params[:email_address])
  end

  def update
    @user.update(role_params)
    redirect_to users_url
  end

  def destroy
    @user.deactivate
    redirect_to users_url
  end

  private
    def role_params
      { role: params.require(:user)[:role].presence_in(%w[ member administrator ]) || "member" }
    end

    def set_user
      @user = User.active.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password)
    end

    def verify_join_code
      head :not_found if Current.account.join_code != params[:join_code]
    end
end
