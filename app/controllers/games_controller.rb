class GamesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @games = Game.order(:id)
                 .with_attached_cover
                 .page params[:page]
    skip_policy_scope
  end

  def show
    @game = Game.find(params[:id])
    skip_authorization
  end

  def new
    @game = Game.new
    authorize @game
  end

  def edit
    @game = Game.find(params[:id])
    authorize @game
  end

  def create
    @game = Game.new(game_params)
    authorize @game
    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, success: "#{@game.name} was successfully created." }
        format.json { render json: @game, status: :created, location: @game }
      else
        format.html do
          flash.now[:error] = "Unable to create game."
          render :new
        end
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @game = Game.find(params[:id])
    authorize @game

    respond_to do |format|
      if @game.update(game_params)
        format.html { render html: @game, success: "#{@game.name} was successfully updated." }
        format.json { render json: @game, status: :success, location: @game }
      else
        format.html do
          flash.now[:error] = "Unable to update game."
          render :edit
        end
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @game = Game.find(params[:id])
    authorize @game
    @game.destroy
    redirect_to games_url, success: "Game was successfully deleted."
  end

  def search
    if params[:query].present?
      @games = Game.search(params[:query]).page(params[:page])
    else
      @games = Game.none.page(params[:page])
    end

    authorize @games

    respond_to do |format|
      format.json { render json: @games }
    end
  end

  private

  def game_params
    params.require(:game).permit(
      :name,
      :description,
      :cover,
      genre_ids: [],
      engine_ids: []
    )
  end
end
