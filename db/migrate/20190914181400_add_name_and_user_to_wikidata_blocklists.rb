# typed: true
class AddNameAndUserToWikidataBlocklists < ActiveRecord::Migration[6.0]
  def change
    change_table :wikidata_blocklists do |t|
      t.text :name, null: false
      t.references :user, null: true, foreign_key: true
    end
  end
end
