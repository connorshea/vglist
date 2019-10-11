# typed: true
class Mutations::UnfavoriteGame < Mutations::BaseMutation
  description "Remove a game from the current user's favorites."

  argument :game_id, ID, required: true, description: "ID of game to unfavorite."

  field :game, Types::GameType, null: true

  def resolve(game_id:)
    game = Game.find(game_id)

    favorite_game = FavoriteGame.find_by(user: @context[:current_user], game: game)

    raise GraphQL::ExecutionError, "FavoriteGame does not exist." if favorite_game.nil?

    favorite_game.destroy

    {
      game: game
    }
  end
end
