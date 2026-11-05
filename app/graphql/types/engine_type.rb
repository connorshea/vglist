# frozen_string_literal: true

module Types
  class EngineType < Types::BaseObject
    description "Video game engines"

    field :id, ID, null: false, description: "ID of the engine."
    field :name, String, null: false, description: "Name of the engine."
    field :wikidata_id, Integer, null: true, description: 'Wikidata identifier'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this engine was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this engine was last updated."

    # Associations
    field :games, GameType.connection_type, null: false, description: "Games built with this engine." do
      argument :sort_by, Enums::ResourceGameSortType, required: false, description: "The order to sort the games in, if any."
    end

    def games(sort_by: nil)
      ResourceGameSort.apply(@object.games.with_attached_cover, sort_by)
    end
  end
end
