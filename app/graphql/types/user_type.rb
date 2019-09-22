# typed: true
module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :username, String, null: false
    field :bio, String, null: true
    field :slug, String, null: false
    field :role, UserRoleType, null: false

    # Associations
    field :game_purchases, [GamePurchaseType], null: true, description: "Games in this user's library."
    field :followers, [UserType], null: true, description: "Users that are following this user."
    field :following, [UserType], null: true, description: "Users that this user is following."
    field :favorite_games, [GameType], null: true, description: "Games that this user has favorited."
  end
end
