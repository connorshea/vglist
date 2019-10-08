# typed: true
module Types
  class FavoriteGameType < Types::BaseObject
    description "This represents a game that has been favorited by a user."

    field :id, ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Associations
    field :game, GameType, null: false
    field :user, UserType, null: false
  end
end
