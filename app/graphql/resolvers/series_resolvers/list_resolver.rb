# frozen_string_literal: true

module Resolvers
  module SeriesResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::SeriesType.connection_type, null: true

      description "List all series'. This is different from the other list queries because series is the plural of series. :("

      argument :sort_by, Types::Enums::SeriesSortType, required: false, description: "The order to sort the series in. Without one, series are ordered by ID."
      argument :name_contains, String, required: false, description: "Only return series whose name contains this text, ignoring case."

      extras [:lookahead]

      STAT_FIELDS = [:games_count, :first_release_year, :last_release_year].freeze

      def resolve(lookahead:, sort_by: nil, name_contains: nil)
        series = Series.all
        # Only pay for the per-series subqueries when a row shows them, not
        # for e.g. the game form's series picker, which loads names only.
        series = series.with_game_stats if selects_stats?(lookahead)
        series = series.name_contains(name_contains) if name_contains.present?

        sorted(series, sort_by)
      end

      private

      # An explicit mapping rather than public_send, so only these scopes can
      # ever be called.
      def sorted(series, sort_by)
        case sort_by
        when :most_games then series.most_games
        when :alphabetical then series.alphabetical
        when :recently_added then series.recently_added
        else series.order(:id)
        end
      end

      def selects_stats?(lookahead)
        nodes = [lookahead.selection(:nodes), lookahead.selection(:edges).selection(:node)]
        nodes.any? { |node| STAT_FIELDS.any? { |field| node.selects?(field) } }
      end
    end
  end
end
