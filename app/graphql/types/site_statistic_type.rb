# typed: strict
module Types
  class SiteStatisticType < Types::BaseObject
    description <<~MARKDOWN
      Historical site statistics for vglist. Most of these values cannot be
      `null`, but some may be if you go back far enough. Make sure to handle
      `null` where necessary.
    MARKDOWN

    field :id, ID, null: false, description: "ID of the statistic record."

    # Actually #created_at, but timestamp works better.
    field :timestamp, GraphQL::Types::ISO8601DateTime,
      null: false,
      method: :created_at,
      description: "The point in time at which these statistics were logged, always UTC."

    field :users, Integer, null: false, description: "The number of Users at this point in time."
    field :games, Integer, null: false, description: "The number of Games at this point in time."
    field :platforms, Integer, null: false, description: "The number of Platforms at this point in time."
    field :series, Integer, null: false, description: "The number of Series at this point in time."
    field :engines, Integer, null: false, description: "The number of Engines at this point in time."
    field :companies, Integer, null: false, description: "The number of Companies at this point in time."
    field :genres, Integer, null: false, description: "The number of Genres at this point in time."
    field :stores, Integer, null: false, description: "The number of Stores at this point in time."
    field :events, Integer, null: false, description: "The number of Events at this point in time."
    field :game_purchases, Integer, null: false, description: "The number of Game Purchases at this point in time."
    field :relationships, Integer, null: false, description: "The number of Relationships at this point in time."
    field :games_with_covers, Integer, null: false, description: "The number of Games with covers at this point in time."
    field :games_with_release_dates, Integer, null: false, description: "The number of Games with release dates at this point in time."
    field :banned_users, Integer, null: false, description: "The number of Banned Users at this point in time."

    # External IDs
    field :mobygames_ids, Integer, null: false, description: "The number of MobyGames IDs at this point in time."
    field :pcgamingwiki_ids, Integer, null: false, description: "The number of PCGamingWiki IDs at this point in time."
    field :wikidata_ids, Integer, null: false, description: "The number of Wikidata IDs at this point in time."
    field :giantbomb_ids, Integer, null: false, description: "The number of GiantBomb IDs at this point in time."
    field :steam_app_ids, Integer, null: false, description: "The number of Steam App IDs at this point in time."
    field :epic_games_store_ids, Integer, null: false, description: "The number of Epic Games Store IDs at this point in time."
    field :gog_ids, Integer, null: false, description: "The number of GOG.com IDs at this point in time."
    field :igdb_ids, Integer, null: true, description: "The number of IGDB IDs at this point in time."

    # Versions
    field :company_versions, Integer, null: true, description: "The number of Company Versions at this point in time."
    field :game_versions, Integer, null: true, description: "The number of Game Versions at this point in time."
    field :genre_versions, Integer, null: true, description: "The number of Genre Versions at this point in time."
    field :engine_versions, Integer, null: true, description: "The number of Engine Versions at this point in time."
    field :platform_versions, Integer, null: true, description: "The number of Platform Versions at this point in time."
    field :series_versions, Integer, null: true, description: "The number of Series Versions at this point in time."
  end
end
