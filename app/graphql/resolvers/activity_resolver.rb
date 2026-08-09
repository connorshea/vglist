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
                       .includes(user: AttachmentPreloads::AVATAR)
                       .joins(:user)
                       .where(users: { privacy: :public_account, banned: false })
      when 'following'
        current_user = @context[:current_user]
        raise GraphQL::ExecutionError, "You must be logged in to view the following feed." if current_user.nil?

        # Following a user doesn't grant permanent visibility: the followed
        # user can go private or get banned afterwards without the
        # relationship being removed. Filter the followed users through the
        # same visibility rule the UserPolicy applies, so the feed can't leak
        # events the policy would withhold.
        user_ids = current_user.following.visible_to(current_user).select(:id)
        # Build the OR relation first with matching structure on both sides
        # (no includes/order), otherwise ActiveRecord raises ArgumentError:
        # "Relation passed to #or must be structurally compatible". Then
        # layer the includes/order on top of the combined relation.
        Views::NewEvent.where(user_id: user_ids)
                       .or(Views::NewEvent.where(user_id: current_user.id))
                       .includes(user: AttachmentPreloads::AVATAR)
                       .recently_created
      end
    end
  end
end
