class GenresController < ApplicationController
  def index
    @genres = Genre.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @genre = Genre.find(params[:id])
    skip_authorization
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

  private

  def genre_params
    params.require(:genre).permit(:name, :description)
  end
end
