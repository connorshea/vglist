class GamePurchasesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @game_purchases = GamePurchase.where(user_id: params[:user_id])
                                  .includes(:game)
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

  def destroy
    @game_purchase = GamePurchase.find(params[:id])
    authorize @game_purchase
    @game_purchase.destroy
  end

  def game_purchase_params
    params.require(:game_purchase).permit(
      :user_id,
      :game_id,
      :comment,
      :score
    )
  end
end
