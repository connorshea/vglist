# frozen_string_literal: true

module Types
  class GameType < Types::BaseObject
    description "Video games"

    field :id, ID, null: false, description: "ID of the game."
    field :name, String, null: false, description: "Name of the game."
    field :release_date, GraphQL::Types::ISO8601Date, null: true, description: "The release date of the game."
    field :avg_rating, Float, null: true, description: "The average rating from all users who own the game."
    field :rating_count, Integer, null: false, description: "The number of ratings across all game purchases associated to this game."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :pcgamingwiki_id, String, null: true, description: "Identifier for PCGamingWiki."
    field :mobygames_id, Integer, null: true, description: "Identifier for the MobyGames database."
    field :giantbomb_id, String, null: true, description: "Identifier for Giant Bomb."
    field :epic_games_store_id, String, null: true, description: "Identifier for the Epic Games Store."
    field :gog_id, String, null: true, description: "Identifier for GOG.com."
    field :igdb_id, String, null: true, description: "Identifier for Internet Game Database."
    field :steam_app_ids, [Integer], null: false, description: "Identifier for Steam games. Games can have more than one Steam App ID, but most will only have one."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was last updated."

    # Assocations
    field :series, SeriesType, null: true, description: "The series that the game belongs to."
    field :developers, CompanyType.connection_type, null: false, short_list: true, description: "Developers of the game."
    field :publishers, CompanyType.connection_type, null: false, short_list: true, description: "Publishers of the game."
    field :engines, EngineType.connection_type, null: false, short_list: true, description: "Game engines that the game runs on."
    field :genres, GenreType.connection_type, null: false, short_list: true, description: "Genres of the game."
    field :platforms, PlatformType.connection_type, null: false, short_list: true, description: "Platforms the game is available on."
    field :owners, UserType.connection_type, null: false, description: "Users who have this game in their libraries."
    field :favoriters, UserType.connection_type, null: false, description: "Users who have favorited this game."
    field :owner_count, Integer, null: false, description: "The number of public, unbanned users who have this game in their library, the same as `owners.totalCount`. Unlike that, it is counted for a whole list of games in one query."
    field :reviews, GamePurchaseType.connection_type, null: false, description: "Library entries for this game that have comments, from public, unbanned users." do
      argument :sort_by, Enums::GameReviewSortType, required: false, default_value: 'recent', description: "The order to sort the reviews in."
    end
    field :activity, EventType.connection_type, null: false, description: "Activity Events about this game (library additions, completion status changes and favorites), from public, unbanned users."

    field :cover_url, String, null: true, description: "URL for the game's cover image. `null` means the game has no associated cover." do
      argument :size, Enums::GameCoverSizeType, required: false, default_value: :small, description: "The size of the game cover image being requested."
    end

    field :is_favorited, Boolean, null: true, resolver_method: :favorited?, description: "Whether the game is in the current user's favorites, or `null` if there is no logged-in user."
    field :is_in_library, Boolean, null: true, resolver_method: :in_library?, description: "Whether the game is in the current user's library, or `null` if there is no logged-in user."
    field :game_purchase_id, ID, null: true, description: 'The ID of the GamePurchase record if the game is in the current user\'s library, or `null` otherwise.'
    field :library_completion_status, Enums::GamePurchaseCompletionStatusType, null: true, description: "The current user's completion status for the game, or `null` if it isn't in their library, has no status, or there is no logged-in user."

    # These two connections are the inverse of `User#gamePurchases` and
    # `User#favoritedGames`, which UserType hides for private and banned users.
    # Without the same filter here they can be used to answer "does this
    # private/banned user own or like this game?". These are a public "who else
    # plays this" list, so they're restricted to public, unbanned accounts for
    # everyone, rather than being tailored to the viewer.
    def owners
      @object.purchasers.public_and_unbanned.with_attached_avatar
    end

    def favoriters
      @object.favoriters.public_and_unbanned.with_attached_avatar
    end

    def owner_count
      LazyOwnerCount.new(@context, @object.id)
    end

    REVIEW_ORDERS = {
      'recent' => [{ updated_at: :desc }, { id: :desc }],
      'highest_rating' => [Arel.sql('game_purchases.rating desc nulls last'), { id: :desc }],
      'lowest_rating' => [Arel.sql('game_purchases.rating asc nulls last'), { id: :desc }]
    }.freeze

    # Reviews are library entries with non-blank comments. Like `owners`, this
    # is a public list, so it only includes public, unbanned users for
    # everyone; GamePurchaseType.authorized? would otherwise drop private
    # users' entries one by one and break pagination.
    def reviews(sort_by:)
      @object.game_purchases
             .joins(:user)
             .merge(User.public_and_unbanned)
             .where.not(comments: '')
             .preload(:platforms, user: AttachmentPreloads::AVATAR)
             .order(*REVIEW_ORDERS.fetch(sort_by))
    end

    # Events whose eventable is one of this game's library entries or
    # favorites. The eventable_type filters let Postgres prune the other
    # branches of the new_events UNION ALL view.
    def activity
      purchase_ids = @object.game_purchases.select(:id)
      favorite_ids = @object.favorites.select(:id)

      Views::NewEvent.where(eventable_type: 'GamePurchase', eventable_id: purchase_ids)
                     .or(Views::NewEvent.where(eventable_type: 'FavoriteGame', eventable_id: favorite_ids))
                     .joins(:user)
                     .merge(User.public_and_unbanned)
                     .preload(user: AttachmentPreloads::AVATAR)
                     .recently_created
    end

    # Get the number of purchases for the game where rating is not nil.
    def rating_count
      @object.game_purchases.where.not(rating: nil).count
    end

    # Get the Steam App ID values as an array.
    def steam_app_ids
      @object.steam_app_ids.map(&:app_id)
    end

    def cover_url(size:)
      cover = @object.sized_cover(size)
      return if cover.nil?

      cover.url
    end

    def favorited?
      return nil if @context[:current_user].nil?

      favorited_game_ids.include?(@object.id)
    end

    def in_library?
      return nil if @context[:current_user].nil?

      library_entries.key?(@object.id)
    end

    def game_purchase_id
      return nil if @context[:current_user].nil?

      library_entries[@object.id]&.first
    end

    def library_completion_status
      return nil if @context[:current_user].nil?

      library_entries[@object.id]&.last
    end

    private

    # The current user's library entries as `game_id => [id, completion_status]`,
    # cached for the duration of the request so isInLibrary/gamePurchaseId/
    # libraryCompletionStatus don't each fire a query per game, nor one each.
    def library_entries
      @context[:current_user_library_entries] ||=
        @context[:current_user].game_purchases.pluck(:game_id, :id, :completion_status)
                               .to_h { |game_id, id, status| [game_id, [id, status]] }
    end

    def favorited_game_ids
      @context[:current_user_favorited_game_ids] ||=
        @context[:current_user].favorite_games.pluck(:game_id).to_set
    end
  end
end
