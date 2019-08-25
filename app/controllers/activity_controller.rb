# typed: true
class ActivityController < ApplicationController
  # NOTE: Uncomment this if you ever add another controller method
  # before_action :authenticate_user!, except: :index

  def index
    @events = GamePurchaseEvent.recently_created
                               .joins(:user)
                               .where(users: { privacy: :public_account })
                               .includes(game_purchase: [:game])
                               .page params[:page]

    skip_policy_scope
  end
end
