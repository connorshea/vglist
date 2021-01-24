# typed: true
class AddIgdbIdsToStatistics < ActiveRecord::Migration[6.1]
  def change
    add_column :statistics, :igdb_ids, :bigint, null: true
  end
end
