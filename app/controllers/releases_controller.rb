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

    @publishers = ReleasePublisher.all
                                  .where(release: @release.id)
                                  .includes(:company)
    @developers = ReleaseDeveloper.all
                                  .where(release: @release.id)
                                  .includes(:company)
  end

  def new
    @release = Release.new
    authorize @release
  end

  def edit
    @release = Release.find(params[:id])
    authorize @release
  end

  def create
    @release = Release.new(release_params)
    authorize @release
    if @release.save
      redirect_to @release, success: "#{@release.name} was successfully created."
    else
      flash.now[:error] = "Unable to save release."
      render :new
    end
  end

  def update
    @release = Release.find(params[:id])
    authorize @release

    if @release.update(release_params)
      redirect_to @release, success: "#{@release.name} was successfully updated."
    else
      flash.now[:error] = "Unable to update release."
      render :edit
    end
  end

  def destroy
    @release = Release.find(params[:id])
    authorize @release
    @release.destroy
    redirect_to releases_url, success: "Release was successfully deleted."
  end

  private

  def release_params
    params.require(:release).permit(:name, :description)
  end
end
