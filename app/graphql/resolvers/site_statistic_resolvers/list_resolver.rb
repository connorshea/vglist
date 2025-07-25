module Resolvers
  module SiteStatisticResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::SiteStatisticType.connection_type, null: true

      description "List all statistics. **Only available to admins.**"

      argument :sort_direction, Types::Enums::SortDirectionType, required: false, description: "Direction to sort the returned list. Defaults to descending.", default_value: 'desc'

      def resolve(sort_direction:)
        Statistic.all.order(created_at: sort_direction)
      end

      def authorized?(**_args)
        raise GraphQL::ExecutionError, "Viewing site statistics is only available to admins." unless AdminPolicy.new(@context[:current_user], nil).statistics?

        true
      end
    end
  end
end
