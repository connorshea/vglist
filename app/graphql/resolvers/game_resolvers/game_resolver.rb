# typed: strict
module Resolvers
  module GameResolvers
    class GameResolver < Resolvers::BaseResolver
      type Types::GameType, null: true

      description "Find a game by ID or one of its external IDs. May only use one of the filters at a time."

      argument :id, ID, required: false, description: "Find a game by its unique ID."
      argument :wikidata_id, Integer, required: false, description: "Find a game by its Wikidata ID."
      argument :giantbomb_id, String, required: false, description: "Find a game by its GiantBomb ID, e.g. `'3030-23708'`."
      argument :igdb_id, String, required: false, description: "Find a game by its IGDB ID."
      argument :mobygames_id, String, required: false, description: "Find a game by its MobyGames ID."
      argument :pcgamingwiki_id, String, required: false, description: "Find a game by its PCGamingWiki ID."
      argument :steam_app_id, Integer, required: false, description: "Find a game by its Steam App ID."
      argument :epic_games_store_id, String, required: false, description: "Find a game by its Epic Games Store ID."
      argument :gog_id, String, required: false, description: "Find a game by its GOG.com ID."

      # Use validator to validate that one of the arguments is being used.
      validates required: {
        one_of: [
          :id,
          :wikidata_id,
          :giantbomb_id,
          :igdb_id,
          :mobygames_id,
          :pcgamingwiki_id,
          :steam_app_id,
          :epic_games_store_id,
          :gog_id
        ],
        message: 'Cannot provide more than one argument to game at a time.'
      }

      sig { params(kwargs: T.untyped).returns(T.nilable(Game)) }
      def resolve(**kwargs)
        if kwargs.key?(:steam_app_id)
          SteamAppId.find_by(app_id: kwargs[:steam_app_id])&.game
        else
          Game.find_by(**kwargs)
        end
      end
    end
  end
end
