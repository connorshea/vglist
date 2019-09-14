class AddWikidataIdIndexToWikidataBlocklists < ActiveRecord::Migration[6.0]
  def change
    add_index :wikidata_blocklists, :wikidata_id, unique: true
  end
end
