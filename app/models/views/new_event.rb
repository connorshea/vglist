module Views
  # A view for aggregating data from the various events tables.
  class NewEvent < ApplicationRecord
    self.table_name = 'new_events'
    self.primary_key = 'id'

    # Readonly since this is a view and we can't edit it.
    readonly

    # belongs_to :eventable
    belongs_to :user, inverse_of: :new_events

    scope :recently_created, -> { order("new_events.created_at desc") }

    enum :event_category, {
      add_to_library: 0,
      change_completion_status: 1,
      favorite_game: 2,
      new_user: 3,
      following: 4
    }

    # Map event categories to their event model classes.
    EVENT_CLASS_MAP = {
      'add_to_library' => Events::GamePurchaseEvent,
      'change_completion_status' => Events::GamePurchaseEvent,
      'favorite_game' => Events::FavoriteGameEvent,
      'new_user' => Events::UserEvent,
      'following' => Events::RelationshipEvent
    }.freeze

    # Get a specific event subclass record based on the ID.
    # When event_category is known, queries only the correct table (1 query instead of up to 4).
    def self.find_event_subclass_by_id(id, category = nil)
      if category && EVENT_CLASS_MAP.key?(category)
        EVENT_CLASS_MAP[category].find_by(id: id)
      else
        event =   Events::GamePurchaseEvent.find_by(id: id)
        event ||= Events::FavoriteGameEvent.find_by(id: id)
        event ||= Events::UserEvent.find_by(id: id)
        event ||= Events::RelationshipEvent.find_by(id: id)
        event
      end
    end

    def subclass
      @_preloaded_subclass || Views::NewEvent.find_event_subclass_by_id(id, event_category)
    end

    def eventable
      subclass&.eventable
    end

    # Batch-load eventables for a collection of events to avoid N+1 queries.
    # Groups events by category, batch-loads subclass records, then preloads eventables.
    def self.preload_eventables(events)
      events_array = events.to_a
      return events_array if events_array.empty?

      grouped = events_array.group_by(&:event_category)
      subclass_map = {}

      grouped.each do |category, category_events|
        klass = EVENT_CLASS_MAP[category]
        next unless klass

        ids = category_events.map(&:id)
        records = klass.where(id: ids).includes(:eventable)
        records.each { |r| subclass_map[r.id] = r }
      end

      events_array.each do |event|
        sub = subclass_map[event.id]
        event.instance_variable_set(:@_preloaded_subclass, sub)
      end

      events_array
    end
  end
end
