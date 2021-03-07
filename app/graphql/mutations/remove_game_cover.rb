# typed: true
class Mutations::RemoveGameCover < Mutations::BaseMutation
  description "Remove the cover from a game. **Only available to moderators and admins.**"

  argument :game_id, ID, required: true, description: "ID of game to remove a cover from."

  field :game, Types::GameType, null: false, description: "The game thats cover was removed."

  sig { params(game_id: String).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(game_id:)
    game = Game.find_by(id: game_id)

    raise GraphQL::ExecutionError, "Game has no cover attached." unless game&.cover&.attached?

    game&.cover&.purge

    {
      game: game
    }
  end

  sig { params(object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    game = Game.find_by(id: object[:game_id])

    return false if game.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to remove this game's cover." unless GamePolicy.new(@context[:current_user], game).remove_cover?

    return true
  end
end
