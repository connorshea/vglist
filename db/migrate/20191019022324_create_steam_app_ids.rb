# typed: true
class CreateSteamAppIds < ActiveRecord::Migration[6.0]
  def change
    # No need for timestamps on this table.
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :steam_app_ids do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :app_id, null: false
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    add_index :steam_app_ids, :app_id, unique: true
  end
end
