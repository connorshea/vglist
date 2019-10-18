# typed: true
module Types
  class QueryType < Types::BaseObject
    field :game, GameType, null: true do
      description "Find a game by ID."
      argument :id, ID, required: true, description: "Find a game by its unique ID."
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

    field :user, UserType, null: true do
      description "Find a user."
      argument :id, ID, required: false, description: "Find a user by their ID."
      argument :username, String, required: false, description: "Find a user by their username."
    end

    field :users, UserType.connection_type, null: true do
      description "List all users."
    end

    field :game_purchase, GamePurchaseType, null: true do
      description "Find a game purchase by ID."
      argument :id, ID, required: true
    end

    field :activity, EventType.connection_type, null: true do
      description "View recent activity."
      argument :feed_type, ActivityFeedType, required: false
    end

    def game(id:)
      Game.find(id)
    end

    def games
      Game.all
    end

    def game_search(query:)
      Game.search(query)
    end

    def series(id:)
      Series.find(id)
    end

    def series_list
      Series.all
    end

    def series_search(query:)
      Series.search(query)
    end

    def company(id:)
      Company.find(id)
    end

    def companies
      Company.all
    end

    def company_search(query:)
      Company.search(query)
    end

    def platform(id:)
      Platform.find(id)
    end

    def platforms
      Platform.all
    end

    def platform_search(query:)
      Platform.search(query)
    end

    def engine(id:)
      Engine.find(id)
    end

    def engines
      Engine.all
    end

    def engine_search(query:)
      Engine.search(query)
    end

    def genre(id:)
      Genre.find(id)
    end

    def genres
      Genre.all
    end

    def genre_search(query:)
      Genre.search(query)
    end

    def user(id: nil, username: nil)
      if !id.nil?
        User.find(id)
      elsif !username.nil?
        User.find_by(username: username)
      else
        raise GraphQL::ExecutionError, "Field 'user' is missing a required argument: 'id' or 'username'"
      end
    end

    def users
      User.all
    end

    def game_purchase(id:)
      GamePurchase.find(id)
    end

    def activity(feed_type: 'following')
      if feed_type == 'global'
        Event.recently_created
             .joins(:user)
             .where(users: { privacy: :public_account })
      elsif feed_type == 'following'
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
