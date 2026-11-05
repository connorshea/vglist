# frozen_string_literal: true

module Types
  class EventType < Types::BaseObject
    connection_type_class(Types::EventConnectionType)

    description "Represents events in the Activity Feed."

    field :id, ID, null: false, description: "The ID of the event, keep in mind that Events - unlike all other models - use UUIDs."
    field :event_category, Enums::EventCategoryType, null: false, description: "The type of event."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this event was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this event was last updated."
    field :completion_status_change, CompletionStatusChangeType, null: true, description: "For `CHANGE_COMPLETION_STATUS` events, the completion status before and after the change. `null` for every other kind of event."

    # Associations
    field :user, UserType, null: false, description: "The user that this event is about."
    field :eventable, EventableUnion, null: false, description: "The 'eventable' type that this event is about. This can be one of a number of different types, depending on the event."

    # The game purchase's `saved_changes` at the time of the event, stored in
    # the `differences` column, e.g. `{ "completion_status" => ["in_progress", "completed"] }`.
    def completion_status_change
      return unless @object.change_completion_status?

      before, after = @object.differences&.dig('completion_status')
      return if before.nil? && after.nil?

      { before: completion_status_name(before), after: completion_status_name(after) }
    end

    private

    # Normalize a stored completion status to its enum name. Events are written
    # with enum names, but integer values are accepted too.
    def completion_status_name(value)
      return GamePurchase.completion_statuses.key(value) if value.is_a?(Integer)

      value if GamePurchase.completion_statuses.key?(value)
    end
  end
end
