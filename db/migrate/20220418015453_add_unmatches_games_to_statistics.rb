class AddUnmatchesGamesToStatistics < ActiveRecord::Migration[6.1]
  def change
    add_column :statistics, :unmatched_games, :bigint, null: true
  end
end
