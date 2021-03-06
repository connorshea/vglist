# typed: true
class Mutations::Games::UnfavoriteGame < Mutations::BaseMutation
  description "Remove a game from the current user's favorites."

  argument :game_id, ID, required: true, description: "ID of game to unfavorite."

  field :game, Types::GameType, null: true, description: "The game being unfavorited."

  sig { params(game_id: T.any(String, Integer)).returns(T::Hash[Symbol, Game]) }
  def resolve(game_id:)
    game = Game.find(game_id)

    favorite_game = FavoriteGame.find_by(user: @context[:current_user], game: game)

    raise GraphQL::ExecutionError, "FavoriteGame does not exist or could not be deleted." unless favorite_game&.destroy

    {
      game: game
    }
  end
end
