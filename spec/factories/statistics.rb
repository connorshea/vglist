# typed: false
FactoryBot.define do
  factory :statistic do
    users { rand(100_000) }
    games { rand(100_000) }
    platforms { rand(100_000) }
    series { rand(100_000) }
    engines { rand(100_000) }
    companies { rand(100_000) }
    genres { rand(100_000) }
    stores { rand(100_000) }
    events { rand(100_000) }
    game_purchases { rand(100_000) }
    relationships { rand(100_000) }
    games_with_covers { rand(100_000) }
    games_with_release_dates { rand(100_000) }
    banned_users { rand(100_000) }
    mobygames_ids { rand(100_000) }
    pcgamingwiki_ids { rand(100_000) }
    wikidata_ids { rand(100_000) }
    giantbomb_ids { rand(100_000) }
    steam_app_ids { rand(100_000) }
    epic_games_store_ids { rand(100_000) }
    gog_ids { rand(100_000) }
    igdb_ids { rand(100_000) }
    company_versions { rand(100_000) }
    game_versions { rand(100_000) }
    genre_versions { rand(100_000) }
    engine_versions { rand(100_000) }
    platform_versions { rand(100_000) }
    series_versions { rand(100_000) }
  end
end
