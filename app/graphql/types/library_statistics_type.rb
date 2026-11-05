# frozen_string_literal: true

module Types
  class LibraryStatisticsType < Types::BaseObject
    description "Aggregate statistics for the games in a user's library. These are calculated across the whole library, so they don't depend on how many game purchases the client has paged through."

    field :games_count, Integer, null: false, description: "The total number of games in the library."
    field :total_hours_played, Float, null: false, description: "The total number of hours the user has played across every game in their library."
    field :completed_count, Integer, null: false, description: "The number of games in the library that are completed or 100% completed."
    field :completion_percentage, Integer, null: false, description: "The percentage of the games in the library that are completed or 100% completed, rounded to the nearest whole number. `0` if the library is empty."
    field :average_rating, Float, null: true, description: "The average of the user's ratings, out of 100, rounded to one decimal place. `null` if the user hasn't rated any of the games in their library."
    field :status_counts, [Types::LibraryStatusCountType], null: false, description: "The number of games in the library for each completion status. Statuses that no game in the library has are omitted, as are games with no completion status, so these counts can add up to less than `gamesCount`."
    field :platform_counts, [Types::LibraryPlatformCountType], null: false, description: "The number of games in the library the user owns on each platform, most-owned first. Platforms the user owns no games on are omitted."
    field :store_counts, [Types::LibraryStoreCountType], null: false, description: "The number of games in the library the user owns from each store, most-owned first. Stores the user owns no games from are omitted."

    # The platform and store counts are only calculated when they're requested,
    # since the profile page doesn't need them. `object[:game_purchases]` is the
    # relation for the library being counted.
    def platform_counts
      counts_for(Platform, :game_purchase_platforms).map { |platform| { platform: platform, count: platform.games_count } }
    end

    def store_counts
      counts_for(Store, :game_purchase_stores).map { |store| { store: store, count: store.games_count } }
    end

    private

    def counts_for(model, join_association)
      join_table = model.reflect_on_association(join_association).table_name

      model.joins(join_association)
           .where(join_table => { game_purchase_id: object[:game_purchases].select(:id) })
           .group(:id)
           .select("#{model.table_name}.*", "COUNT(DISTINCT #{join_table}.game_purchase_id) AS games_count")
           .order(Arel.sql('games_count DESC'), :name)
    end
  end
end
