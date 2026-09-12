namespace :import do
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import Epic Games Store IDs from Wikidata"
  task epic_games: :environment do
    import_external_id(query: epic_games_store_query, column: :epic_games_store_id, label: 'Epic Games Store ID') do |row|
      row[:epicGamesStoreId].to_s
    end
  end

  # SPARQL query for getting all video games with Epic Games Store IDs on Wikidata.
  def epic_games_store_query
    sparql = <<-SPARQL
      SELECT ?item ?epicGamesStoreId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P6278 ?epicGamesStoreId. # Items with an Epic Games Store ID.
      }
    SPARQL

    return sparql
  end
end
