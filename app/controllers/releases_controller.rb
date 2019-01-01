class ReleasesController < ApplicationController
  def index
    @releases = Release.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @release = Release.find(params[:id])
    skip_authorization

    # TODO: Limit this.
    @owners = @release.purchasers
  end
end
