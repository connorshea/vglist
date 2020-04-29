class EnforceUniquenessAtDatabaseLevel < ActiveRecord::Migration[6.0]
  def change
    remove_index :games, :wikidata_id
    add_index :games, :wikidata_id, unique: true
    add_index :game_developers, [:game_id, :company_id], unique: true
    add_index :game_publishers, [:game_id, :company_id], unique: true
  end
end
