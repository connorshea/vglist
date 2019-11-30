# typed: strict
module Types
  class CompanyType < Types::BaseObject
    description "Video game developers and publishers"

    field :id, ID, null: false, description: "ID of the company."
    field :name, String, null: false, description: 'Name of the company.'
    field :wikidata_id, Integer, null: true, description: 'Wikidata identifier'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this company was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this company was last updated."

    # Associations
    field :published_games, GameType.connection_type, null: true, description: "Games published by this company."
    field :developed_games, GameType.connection_type, null: true, description: "Games developed by this company."
  end
end
