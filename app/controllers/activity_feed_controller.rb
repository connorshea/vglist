# typed: true
class ActivityFeedController < ApplicationController
  before_action :authenticate_user!, except: :index

  def index
    @events = GamePurchaseEvent.recently_created
                               .includes(:user, game_purchase: [:game])
                               .page params[:page]
    skip_policy_scope
  end

  def destroy
    @event = GamePurchaseEvent.find(params[:id])
    authorize @event
    @event.destroy
  end
end
