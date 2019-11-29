# typed: true
class Mutations::RemoveGameFromLibrary < Mutations::BaseMutation
  description "Remove a game from the current user's library."

  argument :game_id, ID, required: false, description: "ID of game to remove."
  argument :game_purchase_id, ID, required: false, description: "ID of game purchase to delete."

  field :game, Types::GameType, null: true

  sig { params(game_id: T.nilable(T.any(String, Integer)), game_purchase_id: T.nilable(T.any(String, Integer))).returns(T::Hash[Symbol, Game]) }
  def resolve(game_id: nil, game_purchase_id: nil)
    raise GraphQL::ExecutionError, "Field 'game' is missing a required argument: 'gameId' or 'gamePurchaseId'" if game_id.nil? && game_purchase_id.nil?

    if game_id.nil?
      game_purchase = GamePurchase.find_by(id: game_purchase_id)
      game = game_purchase&.game
    else
      game = Game.find(game_id)

      game_purchase = GamePurchase.find_by(
        user: @context[:current_user],
        game: game
      )
    end

    raise GraphQL::ExecutionError, game_purchase&.errors&.full_messages&.join(", ") unless game_purchase&.destroy

    {
      game: game
    }
  end

  # Only allow the user to delete their own game purchases.
  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    game_purchase = GamePurchase.find(object[:game_purchase_id])

    raise GraphQL::ExecutionError, "You aren't allowed to delete this game purchase." unless GamePurchasePolicy.new(@context[:current_user], game_purchase).destroy?

    return true
  end
end
