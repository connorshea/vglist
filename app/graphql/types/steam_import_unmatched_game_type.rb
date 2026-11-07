# frozen_string_literal: true

module Types
  class SteamImportUnmatchedGameType < Types::BaseObject
    description "A game from a user's Steam library that couldn't be matched to a game in the vglist database during an import."

    field :name, String, null: false, description: "The name of the game on Steam."
    field :steam_app_id, Integer, null: false, description: "The game's Steam App ID."

    def steam_app_id
      @object.steam_id.to_i
    end
  end
end
