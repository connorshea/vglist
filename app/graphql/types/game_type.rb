# typed: true
module Types
  class GameType < Types::BaseObject
    extend T::Sig

    description "Video games"

    field :id, ID, null: false, description: "ID of the game."
    field :name, String, null: false, description: "Name of the game."
    field :release_date, GraphQL::Types::ISO8601Date, null: true, description: "The release date of the game."
    field :avg_rating, Float, null: true, description: "The average rating from all users who own the game."
    field :rating_count, Integer, null: false, description: "The number of ratings across all game purchases associated to this game."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :pcgamingwiki_id, String, null: true, description: "Identifier for PCGamingWiki."
    field :mobygames_id, String, null: true, description: "Identifier for the MobyGames database."
    field :giantbomb_id, String, null: true, description: "Identifier for Giant Bomb."
    field :epic_games_store_id, String, null: true, description: "Identifier for the Epic Games Store."
    field :gog_id, String, null: true, description: "Identifier for GOG.com."
    field :igdb_id, String, null: true, description: "Identifier for Internet Game Database."
    field :steam_app_ids, [Integer], null: false, description: "Identifier for Steam games. Games can have more than one Steam App ID, but most will only have one."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was last updated."

    # Assocations
    field :series, SeriesType, null: true, description: "The series that the game belongs to."
    field :developers, CompanyType.connection_type, null: false, description: "Developers of the game."
    field :publishers, CompanyType.connection_type, null: false, description: "Publishers of the game."
    field :engines, EngineType.connection_type, null: false, description: "Game engines that the game runs on."
    field :genres, GenreType.connection_type, null: false, description: "Genres of the game."
    field :platforms, PlatformType.connection_type, null: false, description: "Platforms the game is available on."
    field :owners, UserType.connection_type, null: false, method: :purchasers, description: "Users who have this game in their libraries."
    field :favoriters, UserType.connection_type, null: false, description: "Users who have favorited this game."

    field :cover_url, String, null: true, description: "URL for the game's cover image. `null` means the game has no associated cover." do
      argument :size, Enums::GameCoverSizeType, required: false, default_value: :small, description: "The size of the game cover image being requested."
    end

    field :is_favorited, Boolean, null: true, resolver_method: :favorited?, description: "Whether the game is in the current user's favorites, or `null` if there is no logged-in user."
    field :is_in_library, Boolean, null: true, resolver_method: :in_library?, description: "Whether the game is in the current user's library, or `null` if there is no logged-in user."
    field :game_purchase_id, ID, null: true, description: 'The ID of the GamePurchase record if the game is in the current user\'s library, or `null` otherwise.'

    # Get the number of purchases for the game where rating is not nil.
    sig { returns(Integer) }
    def rating_count
      @object.game_purchases.where.not(rating: nil).count
    end

    # Get the Steam App ID values as an array.
    sig { returns(T::Array[Integer]) }
    def steam_app_ids
      @object.steam_app_ids.map(&:app_id)
    end

    # TODO: This causes an N+2 query, figure out a better way to do this.
    # https://github.com/rmosolgo/graphql-ruby/issues/1777
    sig { params(size: Symbol).returns(T.nilable(String)) }
    def cover_url(size:)
      cover = T.cast(@object, Game).sized_cover(size)
      return if cover.nil?

      Rails.application.routes.url_helpers.rails_representation_url(cover)
    end

    sig { returns(T.nilable(T::Boolean)) }
    def favorited?
      return nil if @context[:current_user].nil?

      @context[:current_user].favorite_games.find_by(game_id: @object.id).present?
    end

    sig { returns(T.nilable(T::Boolean)) }
    def in_library?
      return nil if @context[:current_user].nil?

      @context[:current_user].game_purchases.find_by(game_id: @object.id).present?
    end

    sig { returns(T.nilable(Integer)) }
    def game_purchase_id
      return nil if @context[:current_user].nil?

      @context[:current_user].game_purchases.find_by(game_id: @object.id)&.id
    end
  end
end
