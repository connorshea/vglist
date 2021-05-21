# typed: true
class Mutations::Games::CreateGame < Mutations::BaseMutation
  description "Create a new game. **Only available when using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the game.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the game item in Wikidata.'
  argument :series_id, ID, required: false, description: 'The ID of the game\'s associated Series.'
  argument :pcgamingwiki_id, String, required: false, description: 'The ID of the game on PCGamingWiki.'
  argument :mobygames_id, String, required: false, description: 'The ID of the game on MobyGames.'
  argument :giantbomb_id, String, required: false, description: 'The ID of the game on the GiantBomb Wiki.'
  argument :epic_games_store_id, String, required: false, description: 'The ID of the game on the Epic Games Store.'
  argument :gog_id, String, required: false, description: 'The ID of the game on GOG.com.'
  argument :igdb_id, String, required: false, description: 'The ID of the game on IGDB.'
  argument :steam_app_ids, [Integer], required: false, description: 'The ID(s) of the game on Steam.'

  field :game, Types::GameType, null: true, description: "The game that was created."

  sig do
    params(
      name: String,
      wikidata_id: T.nilable(T.any(String, Integer)),
      series_id: T.nilable(Integer),
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
    series_id: nil,
    pcgamingwiki_id: nil,
    mobygames_id: nil,
    giantbomb_id: nil,
    epic_games_store_id: nil,
    gog_id: nil,
    igdb_id: nil,
    steam_app_ids: []
  )
    # Use a transaction so the change gets reverted if any part of the record creation fails.
    created_game = Game.transaction do
      game = Game.new(
        name: name,
        wikidata_id: wikidata_id,
        series_id: series_id,
        pcgamingwiki_id: pcgamingwiki_id,
        mobygames_id: mobygames_id,
        giantbomb_id: giantbomb_id,
        epic_games_store_id: epic_games_store_id,
        gog_id: gog_id,
        igdb_id: igdb_id
      )

      raise GraphQL::ExecutionError, game.errors.full_messages.join(", ") unless game.save

      # Create associated SteamAppId records if there are any passed to the mutation.
      steam_app_ids.each do |app_id|
        SteamAppId.create(game: game, app_id: app_id)
      end

      game
    end

    {
      game: created_game
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a game." unless GamePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
