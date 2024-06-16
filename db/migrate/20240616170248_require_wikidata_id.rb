# typed: true
class RequireWikidataId < ActiveRecord::Migration[7.1]
  def change
    change_column_null :genres, :wikidata_id, false
    change_column_null :engines, :wikidata_id, false
    change_column_null :companies, :wikidata_id, false
    change_column_null :series, :wikidata_id, false
    change_column_null :platforms, :wikidata_id, false
  end
end
