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

    # TODO: Limit this.
    @owners = @game.purchasers

    @publishers = GamePublisher.all
                               .where(game: @game.id)
                               .includes(:company)
    @developers = GameDeveloper.all
                               .where(game: @game.id)
                               .includes(:company)
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
        format.json { render json: @game.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def update
    @game = Game.find(params[:id])
    authorize @game

    respond_to do |format|
      if @game.update(game_params)
        format.html { render html: @game, success: "#{@game.name} was successfully updated." }
        format.json { render json: @game, status: :ok, location: @game }
      else
        format.html do
          flash.now[:error] = "Unable to update game."
          render :edit
        end
        format.json { render json: @game.errors.full_messages, status: :unprocessable_entity }
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

  def add_game_to_library
    @game = Game.find(params[:id])
    @user = current_user
    authorize @user

    @game_purchase = GamePurchase.new(game_purchase_params)

    respond_to do |format|
      if @game_purchase.save
        format.html { redirect_to @user, success: "#{@game.name} was successfully added to your library." }
      else
        format.html do
          flash[:error] = "Unable to add game to your library."
          redirect_to game_url(@game)
        end
      end
    end
  end

  def remove_game_from_library
    @user = current_user
    @game = Game.find(params[:id])
    @game_purchase = @user.game_purchases.find_by(game_id: @game.id)
    authorize @user

    respond_to do |format|
      if @game_purchase&.destroy
        format.html { redirect_to @user, success: "#{@game.name} was successfully removed from your library." }
      else
        format.html do
          flash[:error] = "Unable to remove game from your library."
          redirect_to game_url(@game)
        end
      end
    end
  end

  def remove_cover
    @game = Game.find(params[:id])
    authorize @game

    @game.cover.purge

    respond_to do |format|
      format.html { redirect_to @game, success: "Cover successfully removed from #{@game.name}." }
    end
  end

  private

  def game_params
    params.require(:game).permit(
      :name,
      :description,
      :cover,
      genre_ids: [],
      engine_ids: [],
      developer_ids: [],
      publisher_ids: [],
      platform_ids: []
    )
  end

  def game_purchase_params
    params.require(:game_purchase).permit(
      :user_id,
      :game_id
    )
  end
end
