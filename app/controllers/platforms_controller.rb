class PlatformsController < ApplicationController
  def index
    @platforms = Platform.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @platform = Platform.find(params[:id])
    skip_authorization

    @games = @platform.games
                      .with_attached_cover

    respond_to do |format|
      format.html
      format.json { render json: @platform }
    end
  end

  def new
    @platform = Platform.new
    authorize @platform
  end

  def edit
    @platform = Platform.find(params[:id])
    authorize @platform
  end

  def create
    @platform = Platform.new(platform_params)
    authorize @platform
    if @platform.save
      redirect_to @platform, success: "#{@platform.name} was successfully created."
    else
      flash.now[:error] = "Unable to save platform."
      render :new
    end
  end

  def update
    @platform = Platform.find(params[:id])
    authorize @platform

    if @platform.update(platform_params)
      redirect_to @platform, success: "#{@platform.name} was successfully updated."
    else
      flash.now[:error] = "Unable to update platform."
      render :edit
    end
  end

  def destroy
    @platform = Platform.find(params[:id])
    authorize @platform
    @platform.destroy
    redirect_to platforms_url, success: "Platform was successfully deleted."
  end

  def search
    if params[:query].present?
      @platforms = Platform.search(params[:query]).page(params[:page])
    else
      @platforms = Platform.none.page(params[:page])
    end

    authorize @platforms

    respond_to do |format|
      format.json { render json: @platforms }
    end
  end

  private

  def platform_params
    params.require(:platform).permit(:name, :description)
  end
end
