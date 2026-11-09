# frozen_string_literal: true

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

    # Nested associations to preload for each event class's eventable.
    #
    # Game purchases also preload their owner, which `GamePurchaseType`'s
    # authorization check reads for every record. These are loaded by ID rather
    # than through a user's association, so there's no `inverse_of` to fall back
    # on and the owner would otherwise be fetched one purchase at a time.
    EVENTABLE_INCLUDES = {
      Events::GamePurchaseEvent => [:user, { game: AttachmentPreloads::COVER }],
      Events::FavoriteGameEvent => { game: AttachmentPreloads::COVER },
      Events::UserEvent => AttachmentPreloads::AVATAR,
      Events::RelationshipEvent => { followed: AttachmentPreloads::AVATAR }
    }.freeze

    # The same, minus the library entries' and favorites' games, for when
    # the query doesn't read them (see Types::EventConnectionType).
    EVENTABLE_INCLUDES_WITHOUT_GAMES = EVENTABLE_INCLUDES.merge(
      Events::GamePurchaseEvent => [:user],
      Events::FavoriteGameEvent => []
    ).freeze

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
    # Groups events by table, batch-loads subclass records, then preloads eventables.
    # @param include_games [Boolean] Also preload the games (and covers) of
    #   library entries and favorites.
    def self.preload_eventables(events, include_games: true)
      events_array = events.to_a
      return events_array if events_array.empty?

      # Both library events (add_to_library and change_completion_status) are
      # in the same table, so they are loaded together, along with one set of
      # their library entries, games and covers.
      grouped = events_array.group_by { |event| EVENT_CLASS_MAP[event.event_category] }
      includes = include_games ? EVENTABLE_INCLUDES : EVENTABLE_INCLUDES_WITHOUT_GAMES
      subclass_map = {}

      grouped.each do |klass, class_events|
        next unless klass

        ids = class_events.map(&:id)
        records = klass.where(id: ids).includes(eventable: includes[klass])
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
