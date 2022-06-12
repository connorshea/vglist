# typed: true
class EventsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    # Run through each event type to find the event we're trying to delete here.
    @event = Views::NewEvent.find_event_subclass_by_id(params[:id].to_s)

    authorize @event, policy_class: EventPolicy
    T.must(@event).destroy
    redirect_to activity_url, success: "Event was successfully deleted."
  end
end
