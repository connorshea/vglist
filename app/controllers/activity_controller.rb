# typed: false
class ActivityController < ApplicationController
  before_action :authenticate_user!, except: :global

  def global
    @events = Event.recently_created
                   .joins(:user)
                   .where(users: { privacy: :public_account })
                   .includes(eventable: [:game])
                   .page helpers.page_param

    skip_authorization
  end

  def following
    user_ids = current_user.following.map { |u| u.id }
    # Include the user's own activity in the feed.
    user_ids << current_user.id
    @events = Event.recently_created
                   .joins(:user)
                   .where(user_id: user_ids)
                   .page helpers.page_param

    authorize @events.first, policy_class: ActivityPolicy
  end
end
