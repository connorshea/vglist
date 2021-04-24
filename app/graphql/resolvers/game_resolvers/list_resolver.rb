# typed: strict
module Resolvers
  module GameResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::GameType.connection_type, null: true

      description "List all games."

      argument :sort_by, Types::GameSortType, required: false, description: "The order to sort the games in, if any."
      argument :on_platform, ID, required: false, description: "Filter games by the ID of the platform they're on."
      argument :by_year, Integer,
        required: false,
        description: "Filter games by the year of their release date, earliest allowed year is 1950.",
        validates: { numericality: { greater_than_or_equal_to: 1950, allow_null: true } }

      sig do
        params(
          sort_by: T.nilable(String),
          on_platform: T.nilable(String),
          by_year: T.nilable(Integer)
        ).returns(Game::RelationType)
      end
      def resolve(sort_by: nil, on_platform: nil, by_year: nil)
        games = Game.all

        games = games.on_platform(on_platform) unless on_platform.nil?
        games = games.by_year(by_year) unless by_year.nil?

        sort_by.nil? ? games.order(:id) : games.public_send(sort_by.to_sym)
      end
    end
  end
end
