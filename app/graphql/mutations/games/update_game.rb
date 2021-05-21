# typed: true
class Mutations::Games::UpdateGame < Mutations::BaseMutation
  description "Update an existing game. **Only available when using a first-party OAuth Application.**"

  argument :game_id, ID, required: true, description: 'The ID of the game record.'
  argument :name, String, required: false, description: 'The name of the game.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the game item in Wikidata.'
  argument :series_id, ID, required: false, description: 'The ID of the game\'s associated Series.'
  argument :pcgamingwiki_id, String, required: false, description: 'The ID of the game on PCGamingWiki.'
  argument :mobygames_id, String, required: false, description: 'The ID of the game on MobyGames.'
  argument :giantbomb_id, String, required: false, description: 'The ID of the game on the GiantBomb Wiki.'
  argument :epic_games_store_id, String, required: false, description: 'The ID of the game on the Epic Games Store.'
  argument :gog_id, String, required: false, description: 'The ID of the game on GOG.com.'
  argument :igdb_id, String, required: false, description: 'The ID of the game on IGDB.'
  argument :steam_app_ids, [Integer], required: false, description: 'The ID(s) of the game on Steam.'

  field :game, Types::GameType, null: false, description: "The game that was updated."

  # Use `**args` so we don't replace existing fields that aren't provided with `nil`.
  sig do
    params(
      game_id: T.any(String, Integer),
      steam_app_ids: T.nilable(T::Array[Integer]),
      args: T.untyped
    ).returns(T::Hash[Symbol, Game])
  end
  def resolve(
    game_id:,
    steam_app_ids: nil,
    **args
  )
    game = Game.find(game_id)

    raise GraphQL::ExecutionError, game.errors.full_messages.join(", ") unless game.update(**args)

    # Update the steam_app_ids via nested attributes if they're set.
    game.update(steam_app_ids_attributes: steam_app_ids) unless steam_app_ids.nil?

    {
      game: game
    }
  end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    game = Game.find(object[:game_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this game." unless GamePolicy.new(@context[:current_user], game).update?

    return true
  end
end
