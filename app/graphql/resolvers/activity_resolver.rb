# typed: true
module Resolvers
  class ActivityResolver < Resolvers::BaseResolver
    type Types::EventType.connection_type, null: true

    description "View recent activity."

    argument :feed_type, Types::Enums::ActivityFeedType, required: false

    sig { params(feed_type: String).returns(T.nilable(Views::NewEvent::RelationType)) }
    def resolve(feed_type: 'following')
      case feed_type
      when 'global'
        Views::NewEvent.recently_created
             .joins(:user)
             .where(users: { privacy: :public_account })
      when 'following'
        user_ids = @context[:current_user]&.following&.map(&:id)
        # Include the user's own activity in the feed.
        user_ids << @context[:current_user].id
        Views::NewEvent.recently_created
             .joins(:user)
             .where(user_id: user_ids)
      end
    end
  end
end
