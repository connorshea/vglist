# typed: strict
module Types
  class PlatformType < Types::BaseObject
    description "Video game platforms, usually consoles or PC operating systems."

    field :id, ID, null: false, description: "ID of the platform."
    field :name, String, null: false, description: "Name of the platform."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this platform was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this platform was last updated."

    # Associations
    field :games, GameType.connection_type, null: false, description: "Games available on this platform."
  end
end
