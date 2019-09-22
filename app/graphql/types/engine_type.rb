# typed: true
module Types
  class EngineType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :wikidata_id, Integer, null: true

    # Associations
    field :games, [GameType], null: true, description: "Games built with this engine."
  end
end
