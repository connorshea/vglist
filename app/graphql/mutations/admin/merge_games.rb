# typed: true
class Mutations::Admin::MergeGames < Mutations::BaseMutation
  description "Merge one game into another. Re-associates all favorites and game purchases (if possible). **Only available to admins using a first-party OAuth Application.**"

  argument :game_to_keep_id, ID, required: true, description: 'The ID of the game to keep.'
  argument :game_to_merge_id, ID, required: true, description: 'The ID of the game to merge. This game will be deleted.'

  field :game, Types::GameType, null: false, description: "The resulting game that was kept after merging the two."

  sig { params(game_to_keep_id: String, game_to_merge_id: String).returns(T::Hash[Symbol, Game]) }
  def resolve(game_to_keep_id:, game_to_merge_id:)
    game_to_keep = Game.find_by(id: game_to_keep_id)
    game_to_merge = Game.find_by(id: game_to_merge_id)

    raise GraphQL::ExecutionError, "One of the game IDs was invalid." if game_to_keep.nil? || game_to_merge.nil?

    raise GraphQL::ExecutionError, "#{game_to_merge.name} couldn't be merged into #{game_to_keep.name} due to an error." unless GameMergeService.new(game_to_keep, game_to_merge).merge!

    game_to_keep.reload

    {
      game: game_to_keep
    }
  end

  sig { params(object: T.untyped).returns(T.nilable(T::Boolean)) }
  def authorized?(object)
    require_permissions!(:first_party)

    game = Game.find_by(id: object[:game_to_keep_id])

    raise GraphQL::ExecutionError, "You aren't allowed to merge these games." unless GamePolicy.new(@context[:current_user], game).merge?

    return true
  end
end
