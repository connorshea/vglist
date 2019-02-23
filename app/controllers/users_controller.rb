class UsersController < ApplicationController
  def index
    @users = User.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @user = User.friendly.find(params[:id])
    skip_authorization

    # TODO: Paginate this?
    @purchased_games = @user.games
  end

  def update
    @user = User.friendly.find(params[:id])
    authorize @user

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, success: "#{@user.username} was successfully updated." }
      else
        format.html do
          flash[:error] = "Unable to update user."
          redirect_to settings_path
        end
      end
    end
  end

  def update_role
    @user = User.friendly.find(params[:id])
    role = params[:role].to_sym

    authorize @user

    unless [:member, :moderator, :admin].include? role
      flash[:error] = "Invalid role."
      redirect_to(user_path(@user.id)) && return
    end

    if role == :member
      @user.role = :member
    elsif role == :moderator
      @user.role = :moderator
    elsif role == :admin
      @user.role = :admin
    end

    redirect_to @user, success: "#{@user.username} was given the role #{params[:role]}." if @user.save
  end

  def remove_avatar
    @user = User.friendly.find(params[:id])
    authorize @user

    @user.avatar.purge

    respond_to do |format|
      format.html { redirect_to @user, success: "Avatar successfully removed." }
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :bio,
      :avatar
    )
  end
end
