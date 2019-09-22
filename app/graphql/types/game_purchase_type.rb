# typed: true
module Types
  class GamePurchaseType < Types::BaseObject
    field :id, ID, null: false
    field :game, GameType, null: false
    field :user, UserType, null: false
    field :comments, String, null: true
    field :rating, Integer, null: true
    field :hours_played, Float, null: true
    field :platforms, [PlatformType], null: true

    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game purchase was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game purchase was last updated."
  end
end
