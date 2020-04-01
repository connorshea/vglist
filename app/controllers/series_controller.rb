# typed: true
class SeriesController < ApplicationController
  def index
    @series = Series.order(:id).page helpers.page_param
    skip_policy_scope
  end

  def show
    @series = Series.find(params[:id])
    skip_authorization

    @games = @series.games
                    .with_attached_cover
                    .includes(:platforms, :developers)
                    .page helpers.page_param

    respond_to do |format|
      format.html
      format.json { render json: @series }
    end
  end

  def new
    @series = Series.new
    authorize @series
  end

  def edit
    @series = Series.find(params[:id])
    authorize @series
  end

  def create
    @series = Series.new(series_params)
    authorize @series
    if @series.save
      redirect_to @series, success: "#{@series.name} was successfully created."
    else
      flash.now[:error] = "Unable to create series."
      render :new
    end
  end

  def update
    @series = Series.find(params[:id])
    authorize @series

    if @series.update(series_params)
      redirect_to @series, success: "#{@series.name} was successfully updated."
    else
      flash.now[:error] = "Unable to update series."
      render :edit
    end
  end

  def destroy
    @series = Series.find(params[:id])
    authorize @series
    @series.destroy
    redirect_to series_index_url, success: "Series was successfully deleted."
  end

  def search
    if params[:query].present?
      @series = Series.search(params[:query]).page(helpers.page_param)
    else
      @series = Series.none.page(helpers.page_param)
    end

    authorize @series

    respond_to do |format|
      format.json { render json: @series }
    end
  end

  private

  def series_params
    params.typed_require(:series).permit(
      :name,
      :wikidata_id
    )
  end
end
