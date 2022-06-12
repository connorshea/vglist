# typed: true
class ActivityController < ApplicationController
  before_action :authenticate_user!, except: :global

  def global
    @events = Views::NewEvent.recently_created
                   .joins(:user)
                   .where(users: { privacy: :public_account })
                   .page(helpers.page_param)

    skip_authorization
  end

  def following
    user_ids = T.must(current_user&.following).map { |u| u.id }
    # Include the user's own activity in the feed.
    user_ids << T.must(current_user).id
    @events = Views::NewEvent.recently_created
                   .joins(:user)
                   .where(user_id: user_ids)
                   .page(helpers.page_param)

    authorize @events.first, policy_class: ActivityPolicy
  end
end
