# frozen_string_literal: true

module Resolvers
  module SeriesResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::SeriesType.connection_type, null: true

      description "List all series'. This is different from the other list queries because series is the plural of series. :("

      argument :sort_by, Types::Enums::SeriesSortType, required: false, description: "The order to sort the series in. Without one, series are ordered by ID."
      argument :name_contains, String, required: false, description: "Only return series whose name contains this text, ignoring case."

      extras [:lookahead]

      # games_count is a column on series, so only the release years need loading.
      STAT_FIELDS = [:first_release_year, :last_release_year].freeze

      def resolve(lookahead:, sort_by: nil, name_contains: nil)
        series = Series.all
        series = series.with_game_stats if ResourceIndex.selects_any?(lookahead, STAT_FIELDS)
        series = series.name_contains(name_contains) if name_contains.present?

        ResourceIndex.sort(series, sort_by)
      end
    end
  end
end
