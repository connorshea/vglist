# typed: true
class Mutations::AddGameToLibrary < Mutations::BaseMutation
  description "Add a game to the current user's library."

  argument :game_id, ID, required: true, description: "ID of game to add."
  argument :completion_status, Types::GamePurchaseCompletionStatusType, required: false
  argument :rating, Integer, required: false, description: "The game rating (out of 100)."
  argument :hours_played, Float, required: false, description: "The number of hours a game has been played."
  argument :comments, String, required: false
  # TODO: Add platforms.
  # TODO: Add start and completion dates.

  field :game_purchase, Types::GamePurchaseType, null: true

  def resolve(game_id:, completion_status: nil, rating: nil, hours_played: nil, comments: "")
    game = Game.find(game_id)

    game_purchase = GamePurchase.create(
      user: @context[:current_user],
      game: game,
      completion_status: completion_status,
      rating: rating,
      hours_played: hours_played,
      comments: comments
    )

    raise GraphQL::ExecutionError, game_purchase.errors.full_messages.join(", ") unless game_purchase.save

    {
      game_purchase: game_purchase
    }
  end
end
