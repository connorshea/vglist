# typed: true
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
      stores: Store.count,
      events: Event.count,
      game_purchases: GamePurchase.count,
      relationships: Relationship.count,
      games_with_covers: Game.joins(:cover_attachment).count,
      games_with_release_dates: Game.where.not(release_date: nil).count,
      banned_users: User.where(banned: true).count
    }

    @external_id_counts = {
      mobygames_ids: Game.where.not(mobygames_id: nil).count,
      pcgamingwiki_ids: Game.where.not(pcgamingwiki_id: nil).count,
      wikidata_ids: Game.where.not(wikidata_id: nil).count,
      giantbomb_ids: Game.where.not(giantbomb_id: nil).count,
      steam_app_ids: Game.joins(:steam_app_ids).count,
      epic_games_store_ids: Game.where.not(epic_games_store_id: nil).count,
      gog_ids: Game.where.not(gog_id: nil).count
    }

    @statistics = Statistic.all.reverse_order.page helpers.page_param
  end

  def wikidata_blocklist
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy

    @blocklist = WikidataBlocklist.all
                                  .includes(:user)
                                  .page helpers.page_param
  end

  def remove_from_wikidata_blocklist
    authorize nil, policy_class: AdminPolicy
    @blocklist_entry = WikidataBlocklist.find_by(wikidata_id: params[:wikidata_id])

    @blocklist_entry&.destroy

    respond_to do |format|
      format.html { redirect_to admin_wikidata_blocklist_path, notice: 'Wikidata ID successfully removed from blocklist.' }
      format.json { head :no_content }
    end
  end

  def steam_blocklist
    # We don't have anything specific to validate, so just pass nil.
    authorize nil, policy_class: AdminPolicy

    @blocklist = SteamBlocklist.all
                               .includes(:user)
                               .page helpers.page_param
  end

  def remove_from_steam_blocklist
    authorize nil, policy_class: AdminPolicy
    @blocklist_entry = SteamBlocklist.find_by(steam_app_id: params[:steam_app_id])

    @blocklist_entry&.destroy

    respond_to do |format|
      format.html { redirect_to admin_steam_blocklist_path, notice: 'Steam App ID successfully removed from blocklist.' }
      format.json { head :no_content }
    end
  end

  def games_without_wikidata_ids
    authorize nil, policy_class: AdminPolicy

    @games = Game.where(wikidata_id: nil)
                 .with_attached_cover
                 .page helpers.page_param
  end
end
