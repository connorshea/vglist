# typed: true
class GamePurchaseEventsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    @event = GamePurchaseEvent.find(params[:id])
    authorize @event
    @event.destroy
    redirect_to activity_index_url, success: "Event was successfully deleted."
  end
end
