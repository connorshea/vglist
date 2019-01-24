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

    respond_to do |format|
      if @release.save
        format.html { redirect_to @release, success: "#{@release.name} was successfully created." }
        format.json { render json: @release, status: :created, location: @release }
      else
        format.html do
          flash.now[:error] = "Unable to create release."
          render :new
        end
        format.json { render json: @release.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @release = Release.find(params[:id])
    authorize @release

    respond_to do |format|
      if @release.update(release_params)
        format.html { render html: @release, success: "#{@release.name} was successfully updated." }
        format.json { render json: @release, status: :success, location: @release }
      else
        format.html do
          flash.now[:error] = "Unable to update release."
          render :edit
        end
        format.json { render json: @release.errors, status: :unprocessable_entity }
      end
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
    params.require(:release).permit(
      :name,
      :description,
      :game_id,
      :platform_id,
      publisher_ids: [],
      developer_ids: []
    )
  end
end
