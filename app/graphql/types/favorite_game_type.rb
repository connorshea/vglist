# typed: strict
module Types
  class FavoriteGameType < Types::BaseObject
    description "This represents a game that has been favorited by a user."

    field :id, ID, null: false, description: "The ID of the FavoriteGame record."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game was first favorited."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this favorite game was last updated."

    # Associations
    field :game, GameType, null: false, description: "The game being favorited."
    field :user, UserType, null: false, description: "The user that favorited the game."
  end
end
