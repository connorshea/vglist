# typed: strict
module Types
  class EventType < Types::BaseObject
    description "Represents events in the Activity Feed."

    field :id, ID, null: false, description: "The ID of the event, keep in mind that Events - unlike all other models - use UUIDs."
    field :event_category, EventCategoryType, null: false, description: "The type of event."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this event was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this event was last updated."

    # Associations
    field :user, UserType, null: false, description: "The user that this event is about."
    field :eventable, EventableUnion, null: false, description: "The 'eventable' type that this event is about. This can be one of a number of different types, depending on the event."
  end
end
