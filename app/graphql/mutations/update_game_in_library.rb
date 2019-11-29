# typed: true
class Mutations::UpdateGameInLibrary < Mutations::BaseMutation
  description "Add a game to the current user's library."

  argument :game_purchase_id, ID, required: true, description: "ID of game purchase to modify."
  argument :completion_status, Types::GamePurchaseCompletionStatusType, required: false
  argument :rating, Integer, required: false, description: "The game rating (out of 100)."
  argument :hours_played, Float, required: false, description: "The number of hours a game has been played."
  argument :comments, String, required: false
  argument :start_date, GraphQL::Types::ISO8601Date, required: false, description: "The date on which the user started the game."
  argument :completion_date, GraphQL::Types::ISO8601Date, required: false, description: "The date on which the user completed the game."
  argument :platforms, [ID, null: true], required: false, description: "The IDs of platforms that the game is owned on."
  argument :stores, [ID, null: true], required: false, description: "The IDs of stores that the game is owned on."

  field :game_purchase, Types::GamePurchaseType, null: true

  sig do
    params(
      game_purchase_id: T.any(String, Integer),
      attributes: T.untyped
    ).returns(T::Hash[Symbol, GamePurchase])
  end
  def resolve(
    game_purchase_id:,
    **attributes
  )
    game_purchase = GamePurchase.update(game_purchase_id, attributes)

    raise GraphQL::ExecutionError, game_purchase.errors.full_messages.join(", ") unless game_purchase.save

    {
      game_purchase: game_purchase
    }
  end

  # Only allow the user to update their own game purchases.
  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    game_purchase = GamePurchase.find(object[:game_purchase_id])

    raise GraphQL::ExecutionError, "You aren't allowed to edit this game purchase." unless GamePurchasePolicy.new(@context[:current_user], game_purchase).update?

    return true
  end
end
