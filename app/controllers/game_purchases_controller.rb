# typed: true
class GamePurchasesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @game_purchases = GamePurchase.where(user_id: params[:user_id])
                                  .includes(:game, :platforms)
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
    submittable_ids = bulk_game_purchase_params.dig(:ids)
    actual_params = bulk_game_purchase_params.except(:ids)

    # Use update because it allows you to pass an array of records to update
    # and also triggers validations and callbacks (update_all does not).
    respond_to do |format|
      # This looks so dumb because it needs to be in a format like:
      #   update([1, 2, 3], [{ rating: 5 }, { rating: 5 }, { rating: 5 }])
      # so we create an array of x params where all the params are the same.
      if GamePurchase.update(submittable_ids, Array.new(submittable_ids.length, actual_params))
        format.json { render json: @game_purchases, status: :ok }
      else
        # TODO: Get this to work without a type error.
        format.json { render json: T.unsafe(@game_purchases).errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @game_purchase = GamePurchase.find(params[:id])
    authorize @game_purchase
    @game_purchase.destroy
  end

  private

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
      platform_ids: []
    )
  end

  # Only specific game purchase attributes can be modified in bulk.
  def bulk_game_purchase_params
    params.permit(
      :rating,
      :completion_status,
      ids: []
    )
  end
end
