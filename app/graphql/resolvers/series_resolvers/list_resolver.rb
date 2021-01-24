# typed: true
module Resolvers
  module SeriesResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::SeriesType.connection_type, null: true

      description "List all series'. This is different from the other list queries because series is the plural of series. :("

      sig { returns(Series::RelationType) }
      def resolve
        Series.all
      end
    end
  end
end
