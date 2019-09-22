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

    field :company, CompanyType, null: true do
      description "Find a company by ID."
      argument :id, ID, required: true
    end

    field :platform, PlatformType, null: true do
      description "Find a platform by ID."
      argument :id, ID, required: true
    end

    field :engine, EngineType, null: true do
      description "Find an engine by ID."
      argument :id, ID, required: true
    end

    field :genre, GenreType, null: true do
      description "Find a genre by ID."
      argument :id, ID, required: true
    end

    field :user, UserType, null: true do
      description "Find a user by ID."
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

    def company(id:)
      Company.find(id)
    end

    def platform(id:)
      Platform.find(id)
    end

    def engine(id:)
      Engine.find(id)
    end

    def genre(id:)
      Genre.find(id)
    end

    def user(id:)
      User.find(id)
    end
  end
end
