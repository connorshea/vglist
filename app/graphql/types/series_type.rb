# typed: strict
module Types
  class SeriesType < Types::BaseObject
    description "Video game series'"

    field :id, ID, null: false
    field :name, String, null: false
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this series was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this series was last updated."

    # Associations
    field :games, GameType.connection_type, null: true, description: "Games in this series."
  end
end
