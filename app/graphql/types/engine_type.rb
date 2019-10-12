# typed: strict
module Types
  class EngineType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :wikidata_id, Integer, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this engine was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this engine was last updated."

    # Associations
    field :games, GameType.connection_type, null: true, description: "Games built with this engine."
  end
end
