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
        #
        # The IDs are plucked rather than passed as a subquery on purpose.
        # With a subquery Postgres can't estimate how many events match, so
        # it walks the created_at index and filters, which reads most of the
        # events table when the user follows a few quiet accounts. With
        # literal IDs it picks the (user_id, created_at) index for small
        # follow lists and the created_at index for large ones.
        user_ids = current_user.following.visible_to(current_user).pluck(:id)
        Views::NewEvent.where(user_id: [current_user.id, *user_ids])
                       .includes(user: AttachmentPreloads::AVATAR)
                       .recently_created
      end
    end
  end
end
