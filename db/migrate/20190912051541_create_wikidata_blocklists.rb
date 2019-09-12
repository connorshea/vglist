# typed: true
class CreateWikidataBlocklists < ActiveRecord::Migration[6.0]
  def change
    create_table :wikidata_blocklists do |t|
      # Use a bigint just in case Wikidata ever has more than 2.1 billion items.
      t.integer :wikidata_id, null: false, limit: 5, unique: true

      t.timestamps
    end
  end
end
