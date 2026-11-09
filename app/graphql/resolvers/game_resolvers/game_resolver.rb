# frozen_string_literal: true

module Resolvers
  module GameResolvers
    class GameResolver < Resolvers::BaseResolver
      type Types::GameType, null: true

      description "Find a game by ID or one of its external IDs. May only use one of the filters at a time."

      argument :id, ID, required: false, description: "Find a game by its unique ID."
      argument :wikidata_id, Integer, required: false, description: "Find a game by its Wikidata ID."
      argument :giantbomb_id, String, required: false, description: "Find a game by its Giant Bomb Wiki ID, e.g. `'Games/Portal_2'`."
      argument :igdb_id, String, required: false, description: "Find a game by its IGDB ID."
      argument :mobygames_id, Integer, required: false, description: "Find a game by its MobyGames ID."
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

      extras [:lookahead]

      # The games column each lookup argument (other than steam_app_id) filters
      # on. Building the condition from this list, rather than passing the
      # arguments straight to `where`, keeps the filter limited to these columns.
      LOOKUP_COLUMNS = {
        id: :id,
        wikidata_id: :wikidata_id,
        giantbomb_id: :giantbomb_id,
        igdb_id: :igdb_id,
        mobygames_id: :mobygames_id,
        pcgamingwiki_id: :pcgamingwiki_id,
        epic_games_store_id: :epic_games_store_id,
        gog_id: :gog_id
      }.freeze

      def resolve(lookahead:, **kwargs)
        # An explicit null (e.g. `wikidataId: null`) would otherwise match
        # every game without that ID.
        return nil if kwargs.values.any?(&:nil?)

        games = if kwargs.key?(:steam_app_id)
                  Game.joins(:steam_app_ids).where(steam_app_ids: { app_id: kwargs[:steam_app_id] })
                else
                  argument, value = kwargs.first
                  Game.where(LOOKUP_COLUMNS.fetch(argument) => value)
                end

        # Reading the cover URL otherwise takes five queries one after the
        # other (attachment, blob, variant record, and the variant's own
        # attachment and blob). When it's selected, fetch them with the game
        # in one joined query. That one has no LIMIT, since Rails would then
        # need a second query to apply it to the joined rows; every filter is
        # a unique ID, so it matches at most one game anyway.
        return games.first unless lookahead.selects?(:cover_url)

        games.eager_load(AttachmentPreloads::COVER).to_a.first
      end
    end
  end
end
