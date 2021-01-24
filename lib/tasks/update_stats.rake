# typed: false
namespace :vglist do
  namespace :update do
    desc "Create an entry in the statistics table for the current data in the database"
    task stats: :environment do
      Statistic.create!(
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
        banned_users: User.where(banned: true).count,
        mobygames_ids: Game.where.not(mobygames_id: nil).count,
        pcgamingwiki_ids: Game.where.not(pcgamingwiki_id: nil).count,
        wikidata_ids: Game.where.not(wikidata_id: nil).count,
        giantbomb_ids: Game.where.not(giantbomb_id: nil).count,
        steam_app_ids: Game.joins(:steam_app_ids).count,
        epic_games_store_ids: Game.where.not(epic_games_store_id: nil).count,
        gog_ids: Game.where.not(gog_id: nil).count,
        igdb_ids: Game.where.not(igdb_id: nil).count,
        company_versions: Versions::CompanyVersion.count,
        game_versions: Versions::GameVersion.count,
        genre_versions: Versions::GenreVersion.count,
        engine_versions: Versions::EngineVersion.count,
        platform_versions: Versions::PlatformVersion.count,
        series_versions: Versions::SeriesVersion.count
      )
      puts "Statistics table updated."
    end
  end
end
