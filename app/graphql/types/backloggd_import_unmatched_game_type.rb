# frozen_string_literal: true

module Types
  class BackloggdImportUnmatchedGameType < Types::BaseObject
    description "A game from a user's Backloggd list that couldn't be matched to a game in the vglist database during an import."

    field :name, String, null: false, description: "The name of the game on Backloggd."
    field :slug, String, null: false, description: "The game's slug on Backloggd, which is also its IGDB ID."
    field :url, String, null: false, description: "The game's page on Backloggd."

    def name
      @object['name']
    end

    def slug
      @object['slug']
    end

    def url
      "https://backloggd.com/games/#{@object['slug']}/"
    end
  end
end
