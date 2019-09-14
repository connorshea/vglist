# typed: false
class GenresController < ApplicationController
  def index
    @genres = Genre.order(:id).page helpers.page_param
    skip_policy_scope
    respond_to do |format|
      format.html
      format.json { render json: @genres }
    end
  end

  def show
    @genre = Genre.find(params[:id])
    skip_authorization
    @games = @genre.games
                   .with_attached_cover
                   .includes(:platforms, :developers)
                   .page helpers.page_param
  end

  def new
    @genre = Genre.new
    authorize @genre
  end

  def edit
    @genre = Genre.find(params[:id])
    authorize @genre
  end

  def create
    @genre = Genre.new(genre_params)
    authorize @genre
    if @genre.save
      redirect_to @genre, success: "#{@genre.name} was successfully created."
    else
      flash.now[:error] = "Unable to save genre."
      render :new
    end
  end

  def update
    @genre = Genre.find(params[:id])
    authorize @genre

    if @genre.update(genre_params)
      redirect_to @genre, success: "#{@genre.name} was successfully updated."
    else
      flash.now[:error] = "Unable to update genre."
      render :edit
    end
  end

  def destroy
    @genre = Genre.find(params[:id])
    authorize @genre
    @genre.destroy
    redirect_to genres_url, success: "Genre was successfully deleted."
  end

  def search
    if params[:query].present?
      @genres = Genre.search(params[:query]).page(helpers.page_param)
    else
      @genres = Genre.none.page(helpers.page_param)
    end

    authorize @genres

    respond_to do |format|
      format.json { render json: @genres }
    end
  end

  private

  def genre_params
    params.require(:genre).permit(
      :name,
      :description,
      :wikidata_id
    )
  end
end
