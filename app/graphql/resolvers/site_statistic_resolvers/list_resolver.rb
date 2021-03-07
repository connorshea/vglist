# typed: true
module Resolvers
  module SiteStatisticResolvers
    class ListResolver < Resolvers::BaseResolver
      type Types::SiteStatisticType.connection_type, null: true

      description "List all statistics. **Only available to admins.**"

      sig { returns(Statistic::RelationType) }
      def resolve
        Statistic.all
      end

      sig { returns(T::Boolean) }
      def authorized?
        raise GraphQL::ExecutionError, "Viewing site statistics is only available to admins." unless AdminPolicy.new(@context[:current_user], nil).statistics?

        true
      end
    end
  end
end
