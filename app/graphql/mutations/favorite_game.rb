# typed: true
class Mutations::FavoriteGame < Mutations::BaseMutation
  description "Add a game to the current user's favorites."

  argument :game_id, ID, required: true, description: "ID of game to favorite."

  field :game, Types::GameType, null: true

  def resolve(game_id:)
    game = Game.find(game_id)

    FavoriteGame.create!(user: @context[:current_user], game: game)

    {
      game: game
    }
  end
end
