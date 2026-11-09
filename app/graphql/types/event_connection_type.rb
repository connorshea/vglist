# frozen_string_literal: true

class Types::EventConnectionType < Types::BaseConnectionObject
  # Give the `nodes` field the lookahead, so it can tell what will be read
  # from each event.
  def self.define_nodes_field(nullable, field_options: nil)
    super(nullable, field_options: { extras: [:lookahead] }.merge(field_options || {}))
  end
  private_class_method :define_nodes_field

  # Eventable types whose `game` field is preloaded along with its cover.
  GAME_EVENTABLE_TYPES = [Types::GamePurchaseType, Types::FavoriteGameType].freeze

  # Override nodes to batch-preload eventables and avoid N+1 queries.
  #
  # The eventables' games (and covers) are only preloaded when the query
  # selects them. A game's own activity list doesn't, as every event there is
  # about that game, and preloading them cost about ten queries per page.
  def nodes(lookahead:)
    events = super()
    eventable = lookahead.selection(:eventable)
    include_games = GAME_EVENTABLE_TYPES.any? { |type| eventable.selects?(:game, selected_type: type) }
    Views::NewEvent.preload_eventables(events, include_games: include_games)
  end
end
