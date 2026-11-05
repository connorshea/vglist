# frozen_string_literal: true

module Types
  class CompanyType < Types::BaseObject
    description "Video game developers and publishers"

    field :id, ID, null: false, description: "ID of the company."
    field :name, String, null: false, description: 'Name of the company.'
    field :wikidata_id, Integer, null: true, description: 'Wikidata identifier'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this company was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this company was last updated."

    # Associations
    field :published_games, GameType.connection_type, null: false, description: "Games published by this company." do
      argument :sort_by, Enums::ResourceGameSortType, required: false, description: "The order to sort the games in, if any."
    end
    field :developed_games, GameType.connection_type, null: false, description: "Games developed by this company." do
      argument :sort_by, Enums::ResourceGameSortType, required: false, description: "The order to sort the games in, if any."
    end

    def published_games(sort_by: nil)
      ResourceGameSort.apply(@object.published_games.with_attached_cover, sort_by)
    end

    def developed_games(sort_by: nil)
      ResourceGameSort.apply(@object.developed_games.with_attached_cover, sort_by)
    end
  end
end
