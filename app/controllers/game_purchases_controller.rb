# typed: true
class GamePurchasesController < ApplicationController
  extend T::Sig

  before_action :authenticate_user!, except: [:show, :index]

  def index
    @game_purchases = GamePurchase.where(user_id: params[:user_id])
                                  .includes(:game, :platforms, :stores)
    skip_policy_scope
  end

  def show
    @game_purchase = GamePurchase.find(params[:id])
    skip_authorization
  end

  def create
    @game_purchase = GamePurchase.new(game_purchase_params)
    authorize @game_purchase

    respond_to do |format|
      if @game_purchase.save
        format.json { render json: @game_purchase, status: :created, location: @game_purchase }
      else
        format.json { render json: @game_purchase.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def update
    @game_purchase = GamePurchase.find(params[:id])
    authorize @game_purchase

    respond_to do |format|
      if @game_purchase.update(game_purchase_params)
        format.json { render json: @game_purchase, status: :ok, location: @game_purchase }
      else
        format.json { render json: @game_purchase.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def bulk_update
    @game_purchases = GamePurchase.where(id: bulk_game_purchase_params[:ids])

    # Authorize each purchase individually and then skip authorization
    # because Pundit is stupid and will say we didn't check a policy here.
    # Pundit doesn't support validating an array of records, sadly.
    @game_purchases.each { |purchase| authorize purchase }
    skip_authorization

    # Separate the ids and the actual parameters we want to submit.
    submittable_ids = T.cast(bulk_game_purchase_params[:ids], T::Array[Integer])
    # Separate the store ids because we don't want to override them, we want
    # to add to the existing stores a game is owned on.
    store_ids = T.cast(bulk_game_purchase_params[:store_ids] || [], T::Array[Integer])
    # Exclude the ids and store ids from 'actual params', and then filter any
    # nil values to make sure we don't nullify the completion status or rating
    # when just trying to update stores.
    actual_params = bulk_game_purchase_params.except(:ids, :store_ids).reject { |_k, v| v.nil? }

    # Use update because it allows you to pass an array of records to update
    # and also triggers validations and callbacks (update_all does not).
    respond_to do |format|
      # Given an array of store ids and an array of game purchase ids, use
      # #product to create an array of pairs and then trasform them into
      # an array of hashes. We want them to look like this:
      # `[{ store_id: 1, game_purchase_id: 11 }]`.
      store_game_purchases_map = store_ids.product(T.cast(bulk_game_purchase_params[:ids], T::Array[Integer])).map { |pair| { store_id: pair[0], game_purchase_id: pair[1] } }
      # This looks so dumb because it needs to be in a format like:
      #   update([1, 2, 3], [{ rating: 5 }, { rating: 5 }, { rating: 5 }])
      # so we create an array of x params where all the params are the same.
      if GamePurchase.update(submittable_ids, Array.new(submittable_ids.length, actual_params)) \
        && GamePurchaseStore.create(store_game_purchases_map)
        format.json do
          render json: @game_purchases, status: :ok
        end
      end
    end
  end

  def destroy
    @game_purchase = GamePurchase.find(params[:id])
    authorize @game_purchase
    @game_purchase.destroy
  end

  private

  sig { returns(ActionController::Parameters) }
  def game_purchase_params
    params.typed_require(:game_purchase).permit(
      :user_id,
      :game_id,
      :comments,
      :rating,
      :completion_status,
      :start_date,
      :completion_date,
      :hours_played,
      :replay_count,
      platform_ids: [],
      store_ids: []
    )
  end

  # Only specific game purchase attributes can be modified in bulk.
  sig { returns(ActionController::Parameters) }
  def bulk_game_purchase_params
    params.permit(
      :rating,
      :completion_status,
      store_ids: [],
      ids: []
    )
  end
end
