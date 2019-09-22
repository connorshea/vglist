# typed: false
module Types
  class QueryType < Types::BaseObject
    field :game, GameType, null: true do
      description "Find a game by ID."
      argument :id, ID, required: true, description: "Find a game by its unique ID."
    end

    field :game_search, [GameType], null: true do
      description "Find a game by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :series, SeriesType, null: true do
      description "Find a series by ID."
      argument :id, ID, required: true
    end

    field :series_search, [SeriesType], null: true do
      description "Find a series by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :company, CompanyType, null: true do
      description "Find a company by ID."
      argument :id, ID, required: true
    end

    field :company_search, [CompanyType], null: true do
      description "Find a company by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :platform, PlatformType, null: true do
      description "Find a platform by ID."
      argument :id, ID, required: true
    end

    field :platform_search, [PlatformType], null: true do
      description "Find a platform by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :engine, EngineType, null: true do
      description "Find a game engine by ID."
      argument :id, ID, required: true
    end

    field :engine_search, [EngineType], null: true do
      description "Find a game engine by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :genre, GenreType, null: true do
      description "Find a genre by ID."
      argument :id, ID, required: true
    end

    field :genre_search, [GenreType], null: true do
      description "Find a genre by searching based on its name."
      argument :query, String, required: true, description: "Name to search by."
    end

    field :user, UserType, null: true do
      description "Find a user by ID."
      argument :id, ID, required: true
    end

    field :game_purchase, GamePurchaseType, null: true do
      description "Find a game purchase by ID."
      argument :id, ID, required: true
    end

    def game(id:)
      Game.find(id)
    end

    def game_search(query:)
      Game.search(query)
    end

    def series(id:)
      Series.find(id)
    end

    def series_search(query:)
      Series.search(query)
    end

    def company(id:)
      Company.find(id)
    end

    def company_search(query:)
      Company.search(query)
    end

    def platform(id:)
      Platform.find(id)
    end

    def platform_search(query:)
      Platform.search(query)
    end

    def engine(id:)
      Engine.find(id)
    end

    def engine_search(query:)
      Engine.search(query)
    end

    def genre(id:)
      Genre.find(id)
    end

    def genre_search(query:)
      Genre.search(query)
    end

    def user(id:)
      User.find(id)
    end

    def game_purchase(id:)
      GamePurchase.find(id)
    end
  end
end
