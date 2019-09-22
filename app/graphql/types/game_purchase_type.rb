# typed: true
module Types
  class GamePurchaseType < Types::BaseObject
    field :id, ID, null: false
    field :game, GameType, null: false
    field :user, UserType, null: false
    field :comments, String, null: true
    field :rating, Integer, null: true
    field :hours_played, Float, null: true
  end
end
