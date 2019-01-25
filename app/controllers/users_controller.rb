class UsersController < ApplicationController
  def index
    @users = User.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @user = User.find(params[:id])
    skip_authorization

    # TODO: Paginate this?
    @purchased_releases = @user.releases
  end

  def update_role
    @user = User.find(params[:id])
    role = params[:role].to_sym

    authorize @user

    if role == :member
      @user.role = :member
    elsif role == :moderator
      @user.role = :moderator
    elsif role == :admin
      @user.role = :admin
    end

    if @user.save
      redirect_to @user, success: "#{@user.username} was given the role #{params[:role]}."
    else
      flash.now[:error] = "Unable to save user."
      render :new
    end
  end
end
