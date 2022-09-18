# typed: strict
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

      sig do
        params(
          sort_by: T.nilable(String),
          on_platform: T.nilable(String),
          by_year: T.nilable(Integer),
          by_genre: T.nilable(String),
          by_engine: T.nilable(String)
        ).returns(T.untyped)
      end
      def resolve(
        sort_by: nil,
        on_platform: nil,
        by_year: nil,
        by_genre: nil,
        by_engine: nil
      )
        games = Game.all

        games = games.on_platform(on_platform) unless on_platform.nil?
        games = games.by_year(by_year) unless by_year.nil?
        games = games.by_genre(by_genre) unless by_genre.nil?
        games = games.by_engine(by_engine) unless by_engine.nil?

        sort_by.nil? ? games.order(:id) : games.public_send(sort_by.to_sym)
      end
    end
  end
end
