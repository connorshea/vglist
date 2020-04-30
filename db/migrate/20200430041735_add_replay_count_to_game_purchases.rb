class AddReplayCountToGamePurchases < ActiveRecord::Migration[6.0]
  def change
    add_column :game_purchases, :replay_count, :integer, null: false, default: 0

    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE game_purchases ADD CONSTRAINT game_purchases_replay_count_not_negative
          CHECK (replay_count >= 0)
        SQL
      end

      dir.down do
        execute <<~SQL
          ALTER TABLE game_purchases DROP CONSTRAINT game_purchases_replay_count_not_negative
        SQL
      end
    end
  end
end
