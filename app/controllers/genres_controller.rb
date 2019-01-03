class GenresController < ApplicationController
  def index
    @genres = Genre.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @genre = Genre.find(params[:id])
    skip_authorization
  end
end
