# typed: true
class Mutations::Games::UpdateGame < Mutations::BaseMutation
  description "Update an existing game. **Only available when using a first-party OAuth Application.**"

  argument :game_id, ID, required: true, description: 'The ID of the game record.'
  argument :name, String, required: false, description: 'The name of the game.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the game item in Wikidata.'
  argument :release_date, GraphQL::Types::ISO8601Date, required: false, description: 'The date of the game\'s initial release.'
  argument :series_id, ID, required: false, description: 'The ID of the game\'s associated Series.'
  argument :platform_ids, [ID], required: false, description: 'The ID(s) of the game\'s platforms.'
  argument :developer_ids, [ID], required: false, description: 'The ID(s) of the game\'s developers.'
  argument :publisher_ids, [ID], required: false, description: 'The ID(s) of the game\'s publishers.'
  argument :genre_ids, [ID], required: false, description: 'The ID(s) of the game\'s genres.'
  argument :engine_ids, [ID], required: false, description: 'The ID(s) of the game\'s engines.'
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
      platform_ids: T.nilable(T::Array[T.any(String, Integer)]),
      developer_ids: T.nilable(T::Array[T.any(String, Integer)]),
      publisher_ids: T.nilable(T::Array[T.any(String, Integer)]),
      genre_ids: T.nilable(T::Array[T.any(String, Integer)]),
      engine_ids: T.nilable(T::Array[T.any(String, Integer)]),
      steam_app_ids: T.nilable(T::Array[Integer]),
      args: T.untyped
    ).returns(T::Hash[Symbol, Game])
  end
  def resolve(
    game_id:,
    platform_ids: nil,
    developer_ids: nil,
    publisher_ids: nil,
    genre_ids: nil,
    engine_ids: nil,
    steam_app_ids: nil,
    **args
  )
    game = Game.find(game_id)

    raise GraphQL::ExecutionError, game.errors.full_messages.join(", ") unless game.update(**args)

    # Update the steam_app_ids via nested attributes if they're set.
    # Update the other IDs directly.
    other_game_attrs = {
      platform_ids: platform_ids,
      developer_ids: developer_ids,
      publisher_ids: publisher_ids,
      genre_ids: genre_ids,
      engine_ids: engine_ids,
      steam_app_ids_attributes: steam_app_ids
    }.reject(&:nil?)

    raise GraphQL::ExecutionError, game.errors.full_messages.join(", ") unless game.update(**other_game_attrs)

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
