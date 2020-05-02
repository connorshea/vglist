# typed: true
module Types
  class GamePurchaseType < Types::BaseObject
    description "This represents a game that a user has in their library. It includes data like the user's rating for the game, comments, hours played, etc."

    field :id, ID, null: false, description: "ID of the game purchase."
    field :comments, String, null: true, description: "Comments about the game."
    field :rating, Integer, null: true, description: "Rating out of 100."
    field :hours_played, Float, null: true, description: "The number of hours the game has been played by the user, if any."
    field :replay_count, Integer, null: false, description: "The number of times a game has been replayed."
    field :completion_status, GamePurchaseCompletionStatusType, null: true, description: "How far the user has gotten in the game."
    field :start_date, GraphQL::Types::ISO8601Date, null: true, description: "The date on which the user started the game."
    field :completion_date, GraphQL::Types::ISO8601Date, null: true, description: "The date on which the user completed the game."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game purchase was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this game purchase was last updated."

    # Associations
    field :game, GameType, null: false, description: "The game represented by the Game Purchase."
    field :user, UserType, null: false, description: "The owner of the Game Purchase."
    field :platforms, PlatformType.connection_type, null: true, description: "Platforms that the user owns this game on."
    field :stores, StoreType.connection_type, null: true, description: "Stores that the user owns this game on."

    # If the user's profile is private, their game purchases shouldn't be
    # accessible unless explicitly allowed.
    def self.authorized?(object, context)
      return GamePurchasePolicy.new(context[:current_user], object).show?
    end
  end
end
