# typed: true
class Mutations::Games::RemoveGameCover < Mutations::BaseMutation
  description "Remove the cover from a game. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :game_id, ID, required: true, description: "ID of game to remove cover from."

  field :game, Types::GameType, null: false, description: "The game thats cover was removed."

  def resolve(game_id:)
    game = Game.find_by(id: game_id)

    raise GraphQL::ExecutionError, "Game has no cover attached." unless game&.cover&.attached?

    game&.cover&.purge

    {
      game: game
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    game = Game.find_by(id: object[:game_id])

    return false if game.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to remove this game's cover." unless GamePolicy.new(@context[:current_user], game).remove_cover?

    return true
  end
end
