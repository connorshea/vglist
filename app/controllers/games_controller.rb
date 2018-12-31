class GamesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @games = Game.order(:id).page params[:page]
  end

  def show
    @game = Game.find(params[:id])
  end

  def new
    @game = Game.new
 end

  def edit
    @game = Game.find(params[:id])
  end

  def create
    @game = Game.new(game_params)
    if @game.save
      redirect_to @game, notice: "#{game.name} was successfully created."
    else
      render "new", error: "Could not save game."
    end
  end

  def update
    @game = Game.find(params[:id])
	
    if @game.update_attributes(game_params)
      redirect_to @game, notice: "#{@game.name} was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @game = Game.find(params[:id])
    @game.destroy
    redirect_to games_url, notice: "Game was successfully deleted."
  end

  private
  
  def game_params
    params.require(:game).permit(:name, :description)
  end
end
