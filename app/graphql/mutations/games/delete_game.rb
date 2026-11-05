# frozen_string_literal: true

class Mutations::Games::DeleteGame < Mutations::BaseMutation
  description "Delete a game. **Only available to moderators and admins.**"

  argument :game_id, ID, required: true, description: 'The ID of the game to delete.'

  field :deleted, Boolean, null: true, description: "Whether the game was successfully deleted."

  def resolve(game_id:)
    game = Game.find(game_id)

    raise GraphQL::ExecutionError, game.errors.full_messages.join(", ") unless game.destroy

    {
      deleted: true
    }
  end

  def authorized?(object)
    game = Game.find(object[:game_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this game." unless GamePolicy.new(@context[:current_user], game).destroy?

    return true
  end
end
