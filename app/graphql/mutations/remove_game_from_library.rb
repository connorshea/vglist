# typed: true
class Mutations::RemoveGameFromLibrary < Mutations::BaseMutation
  description "Remove a game from the current user's library."

  argument :game_id, ID, required: true, description: "ID of game to remove."

  field :game, Types::GameType, null: true

  sig { params(game_id: Integer).returns(T::Hash[Symbol, Game]) }
  def resolve(game_id:)
    game = Game.find(game_id)

    game_purchase = GamePurchase.find_by(
      user: @context[:current_user],
      game: game
    )

    raise GraphQL::ExecutionError, game_purchase&.errors&.full_messages&.join(", ") unless game_purchase&.destroy

    {
      game: game
    }
  end
end
