# frozen_string_literal: true

module Resolvers
  module GameResolvers
    class RecentLibraryAdditionsResolver < Resolvers::BaseResolver
      type [Types::GameType], null: false

      description <<~DESC.squish
        Games recently added to public users' libraries for the home page,
        most recently added first. Each game appears once, and each user
        contributes only a couple of games. The list is recomputed every few
        minutes.
      DESC

      argument :first, Integer,
        required: false,
        default_value: 6,
        description: "How many games to return, at most #{RecentLibraryAdditions::MAX}.",
        validates: { numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: RecentLibraryAdditions::MAX } }

      extras [:lookahead]

      def resolve(lookahead:, first:)
        GamePreloads.apply_to_list(RecentLibraryAdditions.games(first), lookahead)
      end
    end
  end
end
