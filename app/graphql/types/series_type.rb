# typed: true
module Types
  class SeriesType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :wikidata_id, Integer, null: true

    # Associations
    field :games, [GameType], null: true, description: "Games in this series."
  end
end
