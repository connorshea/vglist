# typed: true
module Types
  class GamePurchaseType < Types::BaseObject
    description "This represents a game that a user has in their library. It includes data like the user's rating for the game, comments, hours played, etc."

    field :id, ID, null: false
    field :game, GameType, null: false
    field :user, UserType, null: false
    field :comments, String, null: true
    field :rating, Integer, null: true, description: "Rating out of 100."
    field :hours_played, Float, null: true
    field :platforms, [PlatformType], null: true, description: "Platforms that the user owns this game on."

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game purchase was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game purchase was last updated."
  end
end
