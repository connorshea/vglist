# typed: true
class Mutations::FavoriteGame < Mutations::BaseMutation
  description "Add a game to the current user's favorites."

  argument :game_id, ID, required: true, description: "ID of game to favorite."

  field :game, Types::GameType, null: true

  sig { params(game_id: T.any(String, Integer)).returns(T::Hash[Symbol, Game]) }
  def resolve(game_id:)
    game = Game.find(game_id)

    favorite = FavoriteGame.create(user: @context[:current_user], game: game)

    raise GraphQL::ExecutionError, favorite.errors.full_messages.join(", ") unless favorite.save

    {
      game: game
    }
  end
end
