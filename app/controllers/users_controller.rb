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
end
