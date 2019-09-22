# typed: true
module Types
  class GenreType < Types::BaseObject
    field :id, ID, null: true
    field :name, String, null: true
    field :wikidata_id, Integer, null: true

    # Associations
    field :games, [GameType], null: true, description: "Games in this genre."
  end
end
