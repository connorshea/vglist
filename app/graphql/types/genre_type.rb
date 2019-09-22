# typed: true
module Types
  class GenreType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :wikidata_id, Integer, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this genre was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this genre was last updated."

    # Associations
    field :games, [GameType], null: true, description: "Games in this genre."
  end
end
