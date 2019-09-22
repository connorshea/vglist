# typed: true
module Types
  class CompanyType < Types::BaseObject
    field :id, ID, null: true
    field :name, String, null: true
    field :wikidata_id, Integer, null: true

    # Associations
    field :published_games, [GameType], null: true, description: "Games published by this company."
    field :developed_games, [GameType], null: true, description: "Games developed by this company."
  end
end
