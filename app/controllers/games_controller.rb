# typed: false
class GamesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @games = Game.all

    @games = @games.on_platform(params[:platform_filter]) if params[:platform_filter]

    case params[:order_by]
    when 'newest'
      @games = @games.newest
    when 'oldest'
      @games = @games.oldest
    when 'recently_updated'
      @games = @games.recently_updated
    when 'least_recently_updated'
      @games = @games.least_recently_updated
    when 'most_favorites'
      @games = @games.most_favorites
    when 'most_owners'
      @games = @games.most_owners
    else
      @games = @games.order(:id)
    end

    @games = @games.with_attached_cover
                   .includes(:platforms, :developers)
                   .page params[:page]

    skip_policy_scope
  end

  def show
    @game = Game.find(params[:id])
    skip_authorization

    @owners = @game.purchasers.limit(10)
    @owners_count = @game.purchasers.count

    @favoriters = User.where(id: @game.favorites.limit(10).collect(&:user_id))
    @favoriters_count = @game.favorites.count

    @game_purchase = current_user.game_purchases.find_by(game_id: @game.id) if current_user

    unless @game.series_id.nil?
      series = Series.find(@game.series_id)
      @games_in_series = series.games
                               .where.not(id: @game.id)
                               .order(Arel.sql('RANDOM()'))
                               .with_attached_cover
                               .limit(3)
    end

    @publishers = @game.publishers
    @developers = @game.developers
  end

  def new
    @game = Game.new
    authorize @game

    # Allow the name and Steam App ID to be passed from the URL params, for prefilling the form.
    @name = params[:name]
    @steam_app_id = params[:steam_app_id]
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
        format.json { render json: @game_purchase }
      else
        format.html do
          flash[:error] = "Unable to add game to your library."
          redirect_to game_url(@game)
        end
        format.json { render json: @game_purchase.errors.full_messages, status: :unprocessable_entity }
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
        format.json { render json: :ok }
      else
        format.html do
          flash[:error] = "Unable to remove game from your library."
          redirect_to game_url(@game)
        end
        format.json { render json: "Unable to remove game from your library.", status: :unprocessable_entity }
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

  def favorite
    @game = Game.find(params[:id])
    authorize @game

    @user = current_user
    @favorite = FavoriteGame.new(game: @game, user: @user)

    respond_to do |format|
      if @favorite.save
        format.json { head :ok }
      else
        format.json { render json: { errors: @game.errors.full_messages } }
      end
    end
  end

  def unfavorite
    @game = Game.find(params[:id])
    authorize @game

    @user = current_user
    @favorite = @user.favorite_games.find_by(game_id: @game.id)

    respond_to do |format|
      if @favorite&.destroy
        format.json { head :ok }
      else
        format.json { render json: { errors: @game.errors.full_messages } }
      end
    end
  end

  private

  def game_params
    params.require(:game).permit(
      :name,
      :description,
      :cover,
      :wikidata_id,
      :pcgamingwiki_id,
      :steam_app_id,
      :mobygames_id,
      :series_id,
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
