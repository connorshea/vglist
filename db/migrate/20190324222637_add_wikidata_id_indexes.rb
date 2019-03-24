class AddWikidataIdIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :companies, :wikidata_id, unique: true
    add_index :engines, :wikidata_id, unique: true
    add_index :games, :wikidata_id, unique: true
    add_index :genres, :wikidata_id, unique: true
    add_index :series, :wikidata_id, unique: true
    add_index :platforms, :wikidata_id, unique: true
  end
end
