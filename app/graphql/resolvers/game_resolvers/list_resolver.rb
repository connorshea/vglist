# frozen_string_literal: true

module Resolvers
  module GameResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::GameType.connection_type, null: true

      description "List all games."

      argument :sort_by, Types::Enums::GameSortType, required: false, description: "The order to sort the games in, if any."
      argument :on_platform, ID, required: false, description: "Filter games by the ID of the platform they're on."
      argument :by_year, Integer,
        required: false,
        description: "Filter games by the year of their release date, earliest allowed year is 1950.",
        validates: { numericality: { greater_than_or_equal_to: 1950, allow_null: true } }
      argument :by_genre, ID, required: false, description: "Filter games by the ID of the genre they're in."
      argument :by_engine, ID, required: false, description: "Filter games by the ID of the engine they use."
      argument :from_year, Integer,
        required: false,
        description: "Filter games to those released in or after this year, earliest allowed year is 1950.",
        validates: { numericality: { greater_than_or_equal_to: 1950, less_than_or_equal_to: 9999, allow_null: true } }
      argument :to_year, Integer,
        required: false,
        description: "Filter games to those released in or before this year, earliest allowed year is 1950.",
        validates: { numericality: { greater_than_or_equal_to: 1950, less_than_or_equal_to: 9999, allow_null: true } }
      argument :exclude_library, Boolean,
        required: false,
        description: "Leave out games in the current user's library. Ignored when there is no logged-in user."

      # Preload based on the fields the client actually selected, rather than
      # eagerly loading every association the list view might need. See
      # `GamePreloads`.
      extras [:lookahead]

      def resolve(
        lookahead:,
        sort_by: nil,
        on_platform: nil,
        by_year: nil,
        by_genre: nil,
        by_engine: nil,
        from_year: nil,
        to_year: nil,
        exclude_library: false
      )
        games = GamePreloads.apply(Game.all, lookahead)

        games = games.on_platform(on_platform) unless on_platform.nil?
        games = games.by_year(by_year) unless by_year.nil?
        games = games.by_genre(by_genre) unless by_genre.nil?
        games = games.by_engine(by_engine) unless by_engine.nil?
        games = games.released_from_year(from_year) unless from_year.nil?
        games = games.released_to_year(to_year) unless to_year.nil?
        current_user = context[:current_user]
        games = games.where.not(id: current_user.game_purchases.select(:game_id)) if exclude_library && current_user

        games = sort_by.nil? ? games.order(:id) : games.public_send(sort_by.to_sym)
        every_game?(games) ? games.extending(CachedRowCount::EveryRow) : games
      end

      private

      # Whether the list still has every game in it, so its totalCount can come
      # from `Game.cached_row_count`. Every filter, `excludeLibrary`, and the
      # sorts that leave games out (e.g. `HIGHEST_AVG_RATING`) add a `where`,
      # and the filters by association add an inner join. Sorting by most
      # favorites left joins favorites but groups by `games.id`, so it still
      # lists each game once.
      #
      # This is only safe because the relation starts from `Game.all`. An
      # association's relation (e.g. a genre's games) keeps its conditions
      # elsewhere, so it can look unfiltered here.
      #
      # @param games [ActiveRecord::Relation<Game>]
      # @return [Boolean]
      def every_game?(games)
        games.where_clause.empty? && games.joins_values.empty?
      end
    end
  end
end
