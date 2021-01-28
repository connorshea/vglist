# typed: strict
module Resolvers
  module SeriesResolvers
    class SeriesResolver < Resolvers::BaseResolver
      type Types::SeriesType, null: true

      description "Find a series by ID."

      argument :id, ID, required: true

      sig { params(id: T.any(String, Integer)).returns(Series) }
      def resolve(id:)
        Series.find(id)
      end
    end
  end
end
