# typed: true
class EventsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    # Run through each event type to find the event we're trying to delete here.
    @event =   Events::GamePurchaseEvent.find_by(id: params[:id])
    @event ||= Events::FavoriteGameEvent.find_by(id: params[:id])
    @event ||= Events::UserEvent.find_by(id: params[:id])
    @event ||= Events::RelationshipEvent.find_by(id: params[:id])

    authorize @event, policy_class: EventPolicy
    T.must(@event).destroy
    redirect_to activity_url, success: "Event was successfully deleted."
  end
end
