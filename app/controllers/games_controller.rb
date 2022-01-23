# typed: true
class GamesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @games = Game.all

    @games = @games.on_platform(params[:platform_filter]) if params[:platform_filter]
    @games = @games.by_year(params[:by_year]) if params[:by_year]

    order_by_sym = T.cast(params[:order_by], T.nilable(String))&.to_sym
    if !order_by_sym.nil? && [
      :newest,
      :oldest,
      :recently_updated,
      :least_recently_updated,
      :most_favorites,
      :most_owners,
      :recently_released,
      :highest_avg_rating
    ].include?(order_by_sym)
      # Call the scope dynamically.
      @games = @games.public_send(order_by_sym)
    else
      @games = @games.order(:id)
    end

    @games = @games.with_attached_cover
                   .includes(:platforms, :developers)
                   .page helpers.page_param

    skip_policy_scope
  end

  def show
    @game = Game.find(params[:id])
    skip_authorization

    @owners = @game.purchasers.limit(10)
    @owners_count = @game.purchasers.count

    @favoriters = @game.favoriters.limit(10)
    @favoriters_count = @game.favorites.count

    @game_purchase = current_user&.game_purchases&.find_by(game_id: @game.id) if current_user

    unless @game.series_id.nil?
      series = T.must(@game.series)
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
    @steam_app_ids = params[:steam_app_id].nil? ? nil : [params[:steam_app_id]]
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
      @games = Game.search(params[:query]).page(helpers.page_param)
    else
      @games = Game.none.page(helpers.page_param)
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
    @game_purchase = @user&.game_purchases&.find_by(game_id: @game.id)
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

    @game.cover&.purge

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
    @favorite = @user&.favorite_games&.find_by(game_id: @game.id)

    respond_to do |format|
      if @favorite&.destroy
        format.json { head :ok }
      else
        format.json { render json: { errors: @game.errors.full_messages } }
      end
    end
  end

  def add_to_wikidata_blocklist
    @game = Game.find(params[:id])

    authorize @game

    @blocklist = WikidataBlocklist.new(user_id: current_user&.id, name: @game.name, wikidata_id: @game.wikidata_id)

    respond_to do |format|
      if @blocklist.save && @game.update(wikidata_id: nil)
        format.html { redirect_to @game, success: "The Wikidata ID for #{@game.name} was successfully added to the blocklist." }
      else
        errors = @blocklist.errors.full_messages.concat(@game.errors.full_messages)
        format.json { render json: { errors: errors } }
      end
    end
  end

  # Check whether a game has been favorited by the user, and return either
  # true or false.
  def favorited
    @game = Game.find(params[:id])
    authorize @game

    respond_to do |format|
      format.json { render json: helpers.game_in_user_favorites?(@game) }
    end
  end

  # Merge one game into another and update any associated records as necessary.
  def merge
    @game_a = Game.find(params[:id])
    @game_b = Game.find(params[:game_b_id])

    authorize @game_a

    respond_to do |format|
      if GameMergeService.new(@game_a, @game_b).merge!
        format.json { redirect_to game_path(@game_a), success: "#{@game_b.name} successfully merged into #{@game_a.name}." }
      else
        format.json { render json: { errors: ["#{@game_b.name} couldn't be merged into #{@game_a.name} due to an error."] }, status: :unprocessable_entity }
      end
    end
  end

  private

  sig { returns(ActionController::Parameters) }
  def game_params
    params.typed_require(:game).permit(
      :name,
      :cover,
      :wikidata_id,
      :pcgamingwiki_id,
      :mobygames_id,
      :giantbomb_id,
      :epic_games_store_id,
      :gog_id,
      :igdb_id,
      :series_id,
      :release_date,
      steam_app_ids_attributes: [
        :id,
        :app_id,
        # Allow _destroy because that's how Rails knows to delete a nested record.
        :_destroy
      ],
      genre_ids: [],
      engine_ids: [],
      developer_ids: [],
      publisher_ids: [],
      platform_ids: []
    )
  end

  sig { returns(ActionController::Parameters) }
  def game_purchase_params
    params.typed_require(:game_purchase).permit(
      :user_id,
      :game_id
    )
  end
end
