# typed: true

class CreateSteamBlocklist < ActiveRecord::Migration[6.0]
  def change
    create_table :steam_blocklist do |t|
      # Use a bigint just in case Steam ever has more than 2.1 billion titles.
      t.integer :steam_app_id, null: false, limit: 5, unique: true, index: { unique: true }
      t.text :name, null: false
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end
