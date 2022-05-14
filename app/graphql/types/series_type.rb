# typed: strict
module Types
  class SeriesType < Types::BaseObject
    description "Video game series'"

    field :id, ID, null: false, description: "ID of the series."
    field :name, String, null: false, description: "Name of the series."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this series was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this series was last updated."

    # Associations
    field :games, GameType.connection_type, null: false, description: "Games in this series."
  end
end
