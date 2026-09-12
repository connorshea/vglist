namespace :import do
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import GOG.com IDs from Wikidata"
  task gog: :environment do
    # A Wikidata GOG.com ID can point at a game or at other GOG catalog entries
    # (movies, etc.); only "game/..." IDs are for games, and we store them
    # without the "game/" prefix.
    import_external_id(query: gog_query, column: :gog_id, label: 'GOG.com ID') do |row|
      gog_id = row[:gogId].to_s
      gog_id.delete_prefix('game/') if gog_id.start_with?('game/')
    end
  end

  # SPARQL query for getting all video games with GOG.com IDs on Wikidata.
  def gog_query
    sparql = <<-SPARQL
      SELECT ?item ?gogId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P2725 ?gogId. # Items with a GOG.com ID.
      }
    SPARQL

    return sparql
  end
end
