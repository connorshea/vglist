# typed: true
class Mutations::Games::CreateGame < Mutations::BaseMutation
  description "Create a new game. **Only available when using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the game.'
  argument :wikidata_id, Integer, required: false, description: 'The ID of the game item in Wikidata.'
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

  # TODO: Add ability to set game cover in mutation.

  field :game, Types::GameType, null: true, description: "The game that was created."

  sig do
    params(
      name: String,
      wikidata_id: T.nilable(Integer),
      release_date: T.nilable(Date),
      series_id: T.nilable(T.any(String, Integer)),
      platform_ids: T::Array[T.any(String, Integer)],
      developer_ids: T::Array[T.any(String, Integer)],
      publisher_ids: T::Array[T.any(String, Integer)],
      genre_ids: T::Array[T.any(String, Integer)],
      engine_ids: T::Array[T.any(String, Integer)],
      pcgamingwiki_id: T.nilable(String),
      mobygames_id: T.nilable(String),
      giantbomb_id: T.nilable(String),
      epic_games_store_id: T.nilable(String),
      gog_id: T.nilable(String),
      igdb_id: T.nilable(String),
      steam_app_ids: T::Array[Integer]
    ).returns(T::Hash[Symbol, Game])
  end
  def resolve(
    name:,
    wikidata_id: nil,
    release_date: nil,
    series_id: nil,
    platform_ids: [],
    developer_ids: [],
    publisher_ids: [],
    genre_ids: [],
    engine_ids: [],
    pcgamingwiki_id: nil,
    mobygames_id: nil,
    giantbomb_id: nil,
    epic_games_store_id: nil,
    gog_id: nil,
    igdb_id: nil,
    steam_app_ids: []
  )
    game = Game.new(
      name: name,
      wikidata_id: wikidata_id,
      release_date: release_date,
      series_id: series_id,
      platform_ids: platform_ids,
      developer_ids: developer_ids,
      publisher_ids: publisher_ids,
      genre_ids: genre_ids,
      engine_ids: engine_ids,
      pcgamingwiki_id: pcgamingwiki_id,
      mobygames_id: mobygames_id,
      giantbomb_id: giantbomb_id,
      epic_games_store_id: epic_games_store_id,
      gog_id: gog_id,
      igdb_id: igdb_id,
      steam_app_ids_attributes: steam_app_ids.map { |app_id| { app_id: app_id } }
    )

    raise GraphQL::ExecutionError, game.errors.full_messages.join(", ") unless game.save

    {
      game: game
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a game." unless GamePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
