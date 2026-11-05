# frozen_string_literal: true

module Types
  class GenreType < Types::BaseObject
    description "Video game genres"

    field :id, ID, null: false, description: "ID of the genre."
    field :name, String, null: false, description: "Name of the genre."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this genre was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this genre was last updated."
    field :games_count, Integer, null: false, description: "The number of games in this genre."

    # Associations
    field :games, GameType.connection_type, null: false, description: "Games in this genre." do
      argument :sort_by, Enums::ResourceGameSortType, required: false, description: "The order to sort the games in, if any."
    end

    def games(sort_by: nil)
      ResourceGameSort.apply(@object.games.with_attached_cover, sort_by)
    end

    # The list resolver loads this with the records (`with_games_count`), so a
    # page of them doesn't count each one's games separately.
    def games_count
      @object.has_attribute?(:index_games_count) ? @object[:index_games_count] : @object.games.count
    end
  end
end
