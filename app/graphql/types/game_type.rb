# typed: true
module Types
  class GameType < Types::BaseObject
    extend T::Sig

    field :id, ID, null: false
    field :name, String, null: false
    field :release_date, GraphQL::Types::ISO8601Date, null: true, description: "The release date of the game."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :pcgamingwiki_id, String, null: true, description: "Identifier for PCGamingWiki."
    field :mobygames_id, String, null: true, description: "Identifier for the MobyGames database."
    field :giantbomb_id, String, null: true, description: "Identifier for Giant Bomb."
    field :steam_app_ids, [Integer], null: true, description: "Identifier for Steam games. Games can have more than one Steam App ID, but most will only have one."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was last updated."

    # Assocations
    field :series, SeriesType, null: true
    field :developers, CompanyType.connection_type, null: true
    field :publishers, CompanyType.connection_type, null: true
    field :engines, EngineType.connection_type, null: true
    field :genres, GenreType.connection_type, null: true
    field :platforms, PlatformType.connection_type, null: true
    field :owners, UserType.connection_type, null: true, method: :purchasers, description: "Users who have this game in their libraries."

    field :cover_url, String, null: true, description: "URL for the game's cover image. `null` means the game has no associated cover."

    # This causes an N+2 query, figure out a better way to do this.
    # https://github.com/rmosolgo/graphql-ruby/issues/1777
    sig { returns(T.nilable(String)) }
    def cover_url
      attachment = @object.cover_attachment
      return if attachment.nil?

      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end

    # Get the Steam App ID values as an array.
    sig { returns(T::Array[Integer]) }
    def steam_app_ids
      @object.steam_app_ids.map { |app_id_record| app_id_record.app_id }
    end
  end
end
