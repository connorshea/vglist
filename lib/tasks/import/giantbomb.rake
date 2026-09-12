# frozen_string_literal: true

namespace :import do
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import Giant Bomb IDs from Wikidata"
  task giantbomb: :environment do
    import_external_id(query: giantbomb_query, column: :giantbomb_id, label: 'Giant Bomb ID') do |row|
      row[:giantbombId].to_s
    end
  end

  # SPARQL query for getting all video games with Giant Bomb IDs on Wikidata.
  def giantbomb_query
    sparql = <<-SPARQL
      SELECT ?item ?giantbombId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P5247 ?giantbombId. # Items with a Giant Bomb ID.
      }
    SPARQL

    return sparql
  end
end
