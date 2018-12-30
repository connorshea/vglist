class ReleasesController < ApplicationController
  def index
    @releases = Release.order(:id).page params[:page]
  end

  def show
    @release = Release.find(params[:id])
  end
end
