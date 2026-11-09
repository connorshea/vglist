# frozen_string_literal: true

module Resolvers
  module GameResolvers
    class UpcomingReleasesResolver < Resolvers::BaseResolver
      type [Types::GameType], null: false

      description <<~DESC.squish
        Games releasing in the next few months for the home page, with games
        that have a cover and more external IDs ranked ahead of sparser
        entries. The list is recomputed every few hours.
      DESC

      argument :first, Integer,
        required: false,
        default_value: 6,
        description: "How many games to return, at most #{UpcomingReleases::MAX}.",
        validates: { numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: UpcomingReleases::MAX } }

      extras [:lookahead]

      def resolve(lookahead:, first:)
        GamePreloads.apply_to_list(UpcomingReleases.games(first), lookahead)
      end
    end
  end
end
