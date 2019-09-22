# typed: true
module Types
  class GenreType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :wikidata_id, Integer, null: true

    # Associations
    field :games, [GameType], null: true, description: "Games in this genre."
  end
end
