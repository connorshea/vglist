# typed: true
module Types
  class QueryType < Types::BaseObject
    extend T::Sig

    description "Queries are GraphQL requests that can be used to request data from vglist's database."

    field :game, GameType, null: true do
      description "Find a game by ID."
      argument :id, ID, required: false, description: "Find a game by its unique ID."
      argument :giantbomb_id, String, required: false, description: "Find a game by its GiantBomb ID, e.g. `'3030-23708'`."
    end

    field :games, GameType.connection_type, null: true do
      description "List all games."
    end

    field :game_search, GameType.connection_type, null: true do
      description "Find a game by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :series, SeriesType, null: true do
      description "Find a series by ID."
      argument :id, ID, required: true
    end

    field :series_list, SeriesType.connection_type, null: true do
      description "List all series'. This is different from the other list queries because series is the plural of series. :("
    end

    field :series_search, SeriesType.connection_type, null: true do
      description "Find a series by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :company, CompanyType, null: true do
      description "Find a company by ID."
      argument :id, ID, required: true
    end

    field :companies, CompanyType.connection_type, null: true do
      description "List all companies."
    end

    field :company_search, CompanyType.connection_type, null: true do
      description "Find a company by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :platform, PlatformType, null: true do
      description "Find a platform by ID."
      argument :id, ID, required: true
    end

    field :platforms, PlatformType.connection_type, null: true do
      description "List all platforms."
    end

    field :platform_search, PlatformType.connection_type, null: true do
      description "Find a platform by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :engine, EngineType, null: true do
      description "Find a game engine by ID."
      argument :id, ID, required: true
    end

    field :engines, EngineType.connection_type, null: true do
      description "List all game engines."
    end

    field :engine_search, EngineType.connection_type, null: true do
      description "Find a game engine by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :genre, GenreType, null: true do
      description "Find a genre by ID."
      argument :id, ID, required: true
    end

    field :genres, GenreType.connection_type, null: true do
      description "List all genres."
    end

    field :genre_search, GenreType.connection_type, null: true do
      description "Find a genre by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :store, StoreType, null: true do
      description "Find a store by ID."
      argument :id, ID, required: true
    end

    field :stores, StoreType.connection_type, null: true do
      description "List all stores."
    end

    field :store_search, StoreType.connection_type, null: true do
      description "Find a store by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :user, UserType, null: true do
      description "Find a user."
      argument :id, ID, required: false, description: "Find a user by their ID."
      argument :username, String, required: false, description: "Find a user by their username."
    end

    field :users, UserType.connection_type, null: true do
      description "List all users."
    end

    field :user_search, UserType.connection_type, null: true do
      description "Find a user by searching based on its username."
      argument :query, String, required: true, description: "Username to search by."
    end

    field :game_purchase, GamePurchaseType, null: true do
      description "Find a game purchase by ID."
      argument :id, ID, required: true
    end

    field :activity, EventType.connection_type, null: true do
      description "View recent activity."
      argument :feed_type, ActivityFeedType, required: false
    end

    sig { params(id: T.nilable(T.any(String, Integer)), giantbomb_id: T.nilable(String)).returns(T.nilable(Game)) }
    def game(id: nil, giantbomb_id: nil)
      if !id.nil?
        Game.find(id)
      elsif !giantbomb_id.nil?
        Game.find_by(giantbomb_id: giantbomb_id)
      else
        raise GraphQL::ExecutionError, "Field 'game' is missing a required argument: 'id' or 'giantbomb_id'"
      end
    end

    sig { returns(Game::RelationType) }
    def games
      Game.all
    end

    sig { params(query: String).returns(Game::RelationType) }
    def game_search(query:)
      Game.search(query)
    end

    sig { params(id: T.any(String, Integer)).returns(Series) }
    def series(id:)
      Series.find(id)
    end

    sig { returns(Series::RelationType) }
    def series_list
      Series.all
    end

    sig { params(query: String).returns(Series::RelationType) }
    def series_search(query:)
      Series.search(query)
    end

    sig { params(id: T.any(String, Integer)).returns(Company) }
    def company(id:)
      Company.find(id)
    end

    sig { returns(Company::RelationType) }
    def companies
      Company.all
    end

    sig { params(query: String).returns(Company::RelationType) }
    def company_search(query:)
      Company.search(query)
    end

    sig { params(id: T.any(String, Integer)).returns(Platform) }
    def platform(id:)
      Platform.find(id)
    end

    sig { returns(Platform::RelationType) }
    def platforms
      Platform.all
    end

    sig { params(query: String).returns(Platform::RelationType) }
    def platform_search(query:)
      Platform.search(query)
    end

    sig { params(id: T.any(String, Integer)).returns(Engine) }
    def engine(id:)
      Engine.find(id)
    end

    sig { returns(Engine::RelationType) }
    def engines
      Engine.all
    end

    sig { params(query: String).returns(Engine::RelationType) }
    def engine_search(query:)
      Engine.search(query)
    end

    sig { params(id: T.any(String, Integer)).returns(Genre) }
    def genre(id:)
      Genre.find(id)
    end

    sig { returns(Genre::RelationType) }
    def genres
      Genre.all
    end

    sig { params(query: String).returns(Genre::RelationType) }
    def genre_search(query:)
      Genre.search(query)
    end

    sig { params(id: T.any(String, Integer)).returns(Store) }
    def store(id:)
      Store.find(id)
    end

    sig { returns(Store::RelationType) }
    def stores
      Store.all
    end

    sig { params(query: String).returns(Store::RelationType) }
    def store_search(query:)
      Store.search(query)
    end

    sig { params(id: T.nilable(T.any(String, Integer)), username: T.nilable(String)).returns(T.nilable(User)) }
    def user(id: nil, username: nil)
      if !id.nil?
        User.find(id)
      elsif !username.nil?
        User.find_by(username: username)
      else
        raise GraphQL::ExecutionError, "Field 'user' is missing a required argument: 'id' or 'username'"
      end
    end

    sig { returns(User::RelationType) }
    def users
      # Exclude banned users from the results.
      User.all.where(banned: false)
    end

    sig { params(query: String).returns(User::RelationType) }
    def user_search(query:)
      User.search(query)
    end

    sig { params(id: T.any(String, Integer)).returns(GamePurchase) }
    def game_purchase(id:)
      GamePurchase.find(id)
    end

    sig { params(feed_type: String).returns(T.nilable(Event::RelationType)) }
    def activity(feed_type: 'following')
      case feed_type
      when 'global'
        Event.recently_created
             .joins(:user)
             .where(users: { privacy: :public_account })
      when 'following'
        user_ids = @context[:current_user]&.following&.map { |u| u.id }
        # Include the user's own activity in the feed.
        user_ids << @context[:current_user].id
        Event.recently_created
             .joins(:user)
             .where(user_id: user_ids)
      end
    end
  end
end
