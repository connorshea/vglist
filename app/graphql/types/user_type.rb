# typed: true
module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :username, String, null: false
    field :bio, String, null: true, description: "User profile description, aka 'bio'."
    field :slug, String, null: false, description: "The user's slug, used for their profile URL."
    field :role, UserRoleType, null: false, description: "User permission level."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this user was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this user was last updated."

    # Associations
    field :game_purchases, [GamePurchaseType], null: true, description: "Games in this user's library."
    field :followers, [UserType], null: true, description: "Users that are following this user."
    field :following, [UserType], null: true, description: "Users that this user is following."
    field :favorite_games, [GameType], null: true, description: "Games that this user has favorited."
  end
end
