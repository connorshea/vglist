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
      relationships: Relationship.count,
      games_with_covers: Game.joins(:cover_attachment).count,
      games_with_release_dates: Game.where.not(release_date: nil).count
    }

    @external_id_counts = {
      mobygames_ids: Game.where.not(mobygames_id: nil).count,
      pcgamingwiki_ids: Game.where.not(pcgamingwiki_id: nil).count,
      wikidata_ids: Game.where.not(wikidata_id: nil).count,
      steam_app_ids: Game.joins(:steam_app_ids).count
    }
  end

  def wikidata_blocklist
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy

    @blocklist = WikidataBlocklist.all
                                  .includes(:user)
                                  .page helpers.page_param
  end
end
