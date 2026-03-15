module Resolvers
  class ActivityResolver < Resolvers::BaseResolver
    type Types::EventType.connection_type, null: true

    description "View recent activity."

    argument :feed_type, Types::Enums::ActivityFeedType, required: false

    def resolve(feed_type: 'following')
      case feed_type
      when 'global'
        Views::NewEvent.recently_created
                       .includes(:user)
                       .joins(:user)
                       .where(users: { privacy: :public_account })
      when 'following'
        raise GraphQL::ExecutionError, "You must be logged in to view the following feed." if @context[:current_user].nil?

        user_ids = @context[:current_user].following.select(:id)
        Views::NewEvent.recently_created
                       .includes(:user)
                       .where(user_id: user_ids)
                       .or(Views::NewEvent.where(user_id: @context[:current_user].id))
      end
    end
  end
end
