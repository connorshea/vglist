# frozen_string_literal: true

module Types
  class SeriesType < Types::BaseObject
    description "Video game series'"

    field :id, ID, null: false, description: "ID of the series."
    field :name, String, null: false, description: "Name of the series."
    field :wikidata_id, Integer, null: true, description: "Identifier for Wikidata."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this series was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this series was last updated."
    field :games_count, Integer, null: false, description: "The number of games in this series."
    field :first_release_year, Integer, null: true, description: "The year the series' earliest game was released. `null` if none of its games have a release date."
    field :last_release_year, Integer, null: true, description: "The year the series' latest game was released. `null` if none of its games have a release date."

    # Associations
    field :games, GameType.connection_type, null: false, description: "Games in this series." do
      argument :sort_by, Enums::ResourceGameSortType, required: false, description: "The order to sort the games in, if any."
    end

    def games(sort_by: nil)
      ResourceGameSort.apply(@object.games.with_attached_cover, sort_by)
    end

    # `seriesList` loads these with the series (`Series.with_game_stats`), so a
    # page of series doesn't count each one's games separately. Elsewhere they
    # are computed for the one record.
    def games_count
      preloaded(:games_count) { @object.games.count }
    end

    def first_release_year
      preloaded(:first_release_year) { @object.games.minimum(:release_date)&.year }
    end

    def last_release_year
      preloaded(:last_release_year) { @object.games.maximum(:release_date)&.year }
    end

    private

    def preloaded(attribute)
      @object.has_attribute?(attribute) ? @object[attribute] : yield
    end
  end
end
