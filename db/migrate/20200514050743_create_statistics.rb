# typed: true
class CreateStatistics < ActiveRecord::Migration[6.0]
  def change
    # Create a table for tracking all statistics over time.
    create_table :statistics do |t|
      t.timestamps
      t.integer :users, null: false
      t.integer :games, null: false
      t.integer :platforms, null: false
      t.integer :series, null: false
      t.integer :engines, null: false
      t.integer :companies, null: false
      t.integer :genres, null: false
      t.integer :stores, null: false
      t.integer :events, null: false
      t.integer :game_purchases, null: false
      t.integer :relationships, null: false
      t.integer :games_with_covers, null: false
      t.integer :games_with_release_dates, null: false
      t.integer :banned_users, null: false
      t.integer :mobygames_ids, null: false
      t.integer :pcgamingwiki_ids, null: false
      t.integer :wikidata_ids, null: false
      t.integer :giantbomb_ids, null: false
      t.integer :steam_app_ids, null: false
      t.integer :epic_games_store_ids, null: false
      t.integer :gog_ids, null: false
    end
  end
end
