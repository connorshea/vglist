# frozen_string_literal: true

module Resolvers
  class ActivityResolver < Resolvers::BaseResolver
    type Types::EventType.connection_type, null: true

    description "View recent activity."

    argument :feed_type, Types::Enums::ActivityFeedType, required: false

    def resolve(feed_type: 'following')
      case feed_type
      when 'global'
        Views::NewEvent.recently_created
                       .includes(user: { avatar_attachment: :blob })
                       .joins(:user)
                       .where(users: { privacy: :public_account })
      when 'following'
        raise GraphQL::ExecutionError, "You must be logged in to view the following feed." if @context[:current_user].nil?

        user_ids = @context[:current_user].following.select(:id)
        # Build the OR relation first with matching structure on both sides
        # (no includes/order), otherwise ActiveRecord raises ArgumentError:
        # "Relation passed to #or must be structurally compatible". Then
        # layer the includes/order on top of the combined relation.
        Views::NewEvent.where(user_id: user_ids)
                       .or(Views::NewEvent.where(user_id: @context[:current_user].id))
                       .includes(user: { avatar_attachment: :blob })
                       .recently_created
      end
    end
  end
end
