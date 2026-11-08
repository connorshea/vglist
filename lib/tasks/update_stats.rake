# frozen_string_literal: true

namespace :vglist do
  namespace :update do
    desc "Recalculate games' owner count, ratings count and average rating, fixing any that have drifted"
    task game_counters: :environment do
      fixed = GameCountersSync.call
      puts "Corrected counters on #{fixed} games."
    end

    desc "Recalculate the game counts on genres, platforms, engines and series, fixing any that have drifted"
    task resource_game_counts: :environment do
      fixed = ResourceGameCountsSync.call
      puts "Corrected game counts on #{fixed} genres, platforms, engines and series."
    end

    desc "Create an entry in the statistics table for the current data in the database"
    task stats: :environment do
      # A cheap daily safety net for the columns behind the Popular, Top rated
      # and Most games sorts.
      Rake::Task["vglist:update:game_counters"].invoke
      Rake::Task["vglist:update:resource_game_counts"].invoke

      Statistic.create!(
        users: User.count,
        games: Game.count,
        platforms: Platform.count,
        series: Series.count,
        engines: Engine.count,
        companies: Company.count,
        genres: Genre.count,
        stores: Store.count,
        events: Views::NewEvent.count,
        game_purchases: GamePurchase.count,
        relationships: Relationship.count,
        games_with_covers: Game.joins(:cover_attachment).count,
        games_with_release_dates: Game.where.not(release_date: nil).count,
        banned_users: User.where(banned: true).count,
        unmatched_games: UnmatchedGame.count,
        mobygames_ids: Game.where.not(mobygames_id: nil).count,
        pcgamingwiki_ids: Game.where.not(pcgamingwiki_id: nil).count,
        wikidata_ids: Game.where.not(wikidata_id: nil).count,
        giantbomb_ids: Game.where.not(giantbomb_id: nil).count,
        steam_app_ids: Game.joins(:steam_app_ids).distinct.count,
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
