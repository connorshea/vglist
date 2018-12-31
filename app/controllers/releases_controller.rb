class ReleasesController < ApplicationController
  def index
    @releases = Release.order(:id).page params[:page]
  end

  def show
    @release = Release.find(params[:id])

    # TODO: Limit this.
    @owners = @release.purchasers
  end
end
