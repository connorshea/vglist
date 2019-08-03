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
    @game_purchases = GamePurchase.where(id: bulk_game_purchase_params[:game_purchase_ids])
    # puts @game_purchases.inspect
    @game_purchases.each { |purchase| authorize purchase }
    puts bulk_game_purchase_params[:game_purchase].to_h

    # Use update because it allows you to pass an array of records to update
    # and also triggers validations and callbacks (update_all does not).
    respond_to do |format|
      if GamePurchase.update(bulk_game_purchase_params[:game_purchase_ids], bulk_game_purchase_params[:game_purchase].to_h)
        format.json { render json: @game_purchases, status: :ok }
      else
        format.json { render json: @game_purchases.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @game_purchase = GamePurchase.find(params[:id])
    authorize @game_purchase
    @game_purchase.destroy
  end

  def game_purchase_params
    params.require(:game_purchase).permit(
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
      game_purchase_ids: []
    )
  end
end
