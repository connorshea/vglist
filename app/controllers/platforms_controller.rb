class PlatformsController < ApplicationController
  def index
    @platforms = Platform.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @platform = Platform.find(params[:id])
    skip_authorization
  end
end
