# frozen_string_literal: true

module Types
  class PlatformType < Types::BaseObject
    description "Video game platforms, usually consoles or PC operating systems."

    field :id, ID, null: false, description: "ID of the platform."
    field :name, String, null: false, description: "Name of the platform."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this platform was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this platform was last updated."
    field :games_count, Integer, null: false, description: "The number of games on this platform."

    # Associations
    field :cover_games, [GameType], null: false, description: "Up to four games on this platform that have a cover, most-owned first, for showing the platform as a mosaic of covers."
    field :games, GameType.connection_type, null: false, description: "Games available on this platform." do
      argument :sort_by, Enums::ResourceGameSortType, required: false, description: "The order to sort the games in, if any."
    end

    def games(sort_by: nil)
      ResourceGameSort.apply(@object.games.with_attached_cover, sort_by, join_table: 'game_platforms')
    end

    def cover_games
      LazyCoverGames.new(@context, @object)
    end
  end
end
