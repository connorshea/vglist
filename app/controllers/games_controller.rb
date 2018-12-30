class GamesController < ApplicationController
  def index
    @games = Game.order(:id).page params[:page]
  end

  def show
    @game = Game.find(params[:id])
  end
end
