# typed: true
class Mutations::DeleteEvent < Mutations::BaseMutation
  description "Delete an event from the Activity Feed. You must be the owner of the event to delete it."

  argument :event_id, ID, required: true, description: "ID of event to delete, will be a UUID."

  field :deleted, Boolean, null: false, description: "Whether the event was deleted successfully or not."

  def resolve(event_id:)
    event = Views::NewEvent.find_event_subclass_by_id(event_id)

    raise GraphQL::ExecutionError, "Event does not exist or could not be deleted." unless event&.destroy

    {
      deleted: true
    }
  end

  def authorized?(object)
    event = Views::NewEvent.find_event_subclass_by_id(object[:event_id])

    return false if event.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to delete this event." unless EventPolicy.new(@context[:current_user], event).destroy?

    return true
  end
end
