# typed: true
module Types
  class GameType < Types::BaseObject
    extend T::Sig

    description "Video games"

    field :id, ID, null: false, description: "ID of the game."
    field :name, String, null: false, description: "Name of the game."
    field :release_date, GraphQL::Types::ISO8601Date, null: true, description: "The release date of the game."
    field :avg_rating, Float, null: true, description: "The average rating from all users who own the game."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :pcgamingwiki_id, String, null: true, description: "Identifier for PCGamingWiki."
    field :mobygames_id, String, null: true, description: "Identifier for the MobyGames database."
    field :giantbomb_id, String, null: true, description: "Identifier for Giant Bomb."
    field :epic_games_store_id, String, null: true, description: "Identifier for the Epic Games Store."
    field :gog_id, String, null: true, description: "Identifier for GOG.com."
    field :steam_app_ids, [Integer], null: true, description: "Identifier for Steam games. Games can have more than one Steam App ID, but most will only have one."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was last updated."

    # Assocations
    field :series, SeriesType, null: true, description: "The series that the game belongs to."
    field :developers, CompanyType.connection_type, null: true, description: "Developers of the game."
    field :publishers, CompanyType.connection_type, null: true, description: "Publishers of the game."
    field :engines, EngineType.connection_type, null: true, description: "Game engines that the game runs on."
    field :genres, GenreType.connection_type, null: true, description: "Genres of the game."
    field :platforms, PlatformType.connection_type, null: true, description: "Platforms the game is available on."
    field :owners, UserType.connection_type, null: true, method: :purchasers, description: "Users who have this game in their libraries."

    field :cover_url, String, null: true, description: "URL for the game's cover image. `null` means the game has no associated cover." do
      argument :size, GameCoverSizeType, required: false, default_value: :small, description: "The size of the game cover image being requested."
    end

    # This causes an N+2 query, figure out a better way to do this.
    # https://github.com/rmosolgo/graphql-ruby/issues/1777
    sig { params(size: Symbol).returns(T.nilable(String)) }
    def cover_url(size:)
      cover = T.cast(@object, Game).cover_attachment
      return if cover.nil?

      width, height = Game::COVER_SIZES[size]
      cover_variant = cover.variant(
        resize_to_fill: [width, height],
        gravity: 'Center',
        crop: "#{width}x#{height}+0+0"
      )

      Rails.application.routes.url_helpers.rails_representation_url(cover_variant)
    end

    # Get the Steam App ID values as an array.
    sig { returns(T::Array[Integer]) }
    def steam_app_ids
      @object.steam_app_ids.map(&:app_id)
    end
  end
end
