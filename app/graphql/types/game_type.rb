# typed: strict
module Types
  class GameType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :wikidata_id, Integer, null: true, description: "Identifier in Wikidata."
    field :pcgamingwiki_id, String, null: true, description: "Identifier on PCGamingWiki."
    field :mobygames_id, String, null: true, description: "Identifier in the MobyGames database."
    # TODO: Add a field for steam_app_id when the Steam App IDs are split into their own separate model.
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was last updated."

    # Assocations
    field :series, SeriesType, null: true
    field :developers, [CompanyType], null: true
    field :publishers, [CompanyType], null: true
    field :engines, [EngineType], null: true
    field :genres, [GenreType], null: true
    field :platforms, [PlatformType], null: true
    field :owners, [UserType], null: true, method: :purchasers, description: "Users who have this game in their libraries."
  end
end
