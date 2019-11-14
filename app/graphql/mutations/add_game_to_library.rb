# typed: true
class Mutations::AddGameToLibrary < Mutations::BaseMutation
  description "Add a game to the current user's library."

  argument :game_id, ID, required: true, description: "ID of game to add."
  argument :completion_status, Types::GamePurchaseCompletionStatusType, required: false
  argument :rating, Integer, required: false, description: "The game rating (out of 100)."
  argument :hours_played, Float, required: false, description: "The number of hours a game has been played."
  argument :comments, String, required: false
  argument :start_date, GraphQL::Types::ISO8601Date, required: false, description: "The date on which the user started the game."
  argument :completion_date, GraphQL::Types::ISO8601Date, required: false, description: "The date on which the user completed the game."
  # TODO: Add platforms.

  field :game_purchase, Types::GamePurchaseType, null: true

  sig do
    params(
      game_id: T.any(String, Integer),
      completion_status: T.nilable(T.untyped),
      rating: T.nilable(Integer),
      hours_played: T.nilable(Float),
      comments: String,
      start_date: T.nilable(Date),
      completion_date: T.nilable(Date)
    ).returns(T::Hash[Symbol, GamePurchase])
  end
  def resolve(game_id:, completion_status: nil, rating: nil, hours_played: nil, comments: "", start_date: nil, completion_date: nil)
    game = Game.find(game_id)

    game_purchase = GamePurchase.create(
      user: @context[:current_user],
      game: game,
      completion_status: completion_status,
      rating: rating,
      hours_played: hours_played,
      comments: comments,
      start_date: start_date,
      completion_date: completion_date
    )

    raise GraphQL::ExecutionError, game_purchase.errors.full_messages.join(", ") unless game_purchase.save

    {
      game_purchase: game_purchase
    }
  end
end
