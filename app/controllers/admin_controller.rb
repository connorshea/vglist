# typed: false
class AdminController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy

    @counts = {
      users: User.count,
      games: Game.count,
      platforms: Platform.count,
      series: Series.count,
      engines: Engine.count,
      companies: Company.count,
      genres: Genre.count,
      events: Event.count,
      game_purchases: GamePurchase.count,
      relationships: Relationship.count
    }
  end

  def wikidata_blocklist
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy

    @blocklist = WikidataBlocklist.all
                                  .includes(:user)
                                  .page params[:page]
  end
end
