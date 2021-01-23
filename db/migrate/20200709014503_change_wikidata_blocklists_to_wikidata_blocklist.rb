# typed: true
class ChangeWikidataBlocklistsToWikidataBlocklist < ActiveRecord::Migration[6.0]
  def change
    rename_table :wikidata_blocklists, :wikidata_blocklist
  end
end
