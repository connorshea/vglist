# typed: true
module Types
  class GameType < Types::BaseObject
    extend T::Sig

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :wikidata_id, Integer, null: true, description: "Identifier in Wikidata."
    field :pcgamingwiki_id, String, null: true, description: "Identifier on PCGamingWiki."
    field :mobygames_id, String, null: true, description: "Identifier in the MobyGames database."
    # TODO: Add a field for steam_app_id when the Steam App IDs are split into their own separate model.
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was last updated."
    # TODO: Add a field for release_date once the Date type is included in graphql-ruby.

    # Assocations
    field :series, SeriesType, null: true
    field :developers, [CompanyType], null: true
    field :publishers, [CompanyType], null: true
    field :engines, [EngineType], null: true
    field :genres, [GenreType], null: true
    field :platforms, [PlatformType], null: true
    field :owners, [UserType], null: true, method: :purchasers, description: "Users who have this game in their libraries."

    field :cover_url, String, null: true, description: "URL for the game's cover image. `null` means the game has no associated cover."

    # This causes an N+2 query, figure out a better way to do this.
    # https://github.com/rmosolgo/graphql-ruby/issues/1777
    sig { returns(T.nilable(String)) }
    def cover_url
      attachment = @object.cover_attachment
      return if attachment.nil?

      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end
  end
end
