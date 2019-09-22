# typed: true
module Types
  class CompanyType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false, description: 'Company name'
    field :wikidata_id, Integer, null: true, description: 'Wikidata identifier'

    # Associations
    field :published_games, [GameType], null: true, description: "Games published by this company."
    field :developed_games, [GameType], null: true, description: "Games developed by this company."
  end
end
