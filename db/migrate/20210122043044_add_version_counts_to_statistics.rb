# typed: true
class AddVersionCountsToStatistics < ActiveRecord::Migration[6.1]
  def change
    add_column :statistics, :company_versions, :bigint, null: true
    add_column :statistics, :game_versions, :bigint, null: true
    add_column :statistics, :genre_versions, :bigint, null: true
    add_column :statistics, :engine_versions, :bigint, null: true
    add_column :statistics, :platform_versions, :bigint, null: true
    add_column :statistics, :series_versions, :bigint, null: true
  end
end
