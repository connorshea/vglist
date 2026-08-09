# frozen_string_literal: true

class Mutations::Games::FavoriteGame < Mutations::BaseMutation
  description "Add a game to the current user's favorites."

  argument :game_id, ID, required: true, description: "ID of game to favorite."

  field :game, Types::GameType, null: true, description: "The game that was added to the user's library."

  def resolve(game_id:)
    game = Game.find(game_id)

    favorite = FavoriteGame.create(user: @context[:current_user], game: game)

    raise GraphQL::ExecutionError, favorite.errors.full_messages.join(", ") unless favorite.save

    {
      game: game
    }
  end

  def authorized?(object)
    game = Game.find_by(id: object[:game_id])

    return false if game.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to favorite this game." unless GamePolicy.new(@context[:current_user], game).favorite?

    return true
  end
end
