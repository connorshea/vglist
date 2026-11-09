# frozen_string_literal: true

namespace :import do
  require 'wikidata_sparql'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import Giant Bomb Wiki IDs (Wikidata P14470) from Wikidata"
  task giantbomb: :environment do
    import_external_id(query: giantbomb_query, column: :giantbomb_id, label: 'Giant Bomb ID') do |row|
      row[:giantbombId].to_s
    end
  end

  # SPARQL query for getting all video games with Giant Bomb Wiki IDs on
  # Wikidata. P14470 values are wiki page titles like "Games/Portal_2". The
  # old "3030-1539"-style IDs (P5247) are the former scheme and no longer
  # resolve on Giant Bomb.
  def giantbomb_query
    sparql = <<-SPARQL
      SELECT ?item ?giantbombId WHERE {
        ?item wdt:P31 wd:Q7889; # Instances of video games
              wdt:P14470 ?giantbombId. # Items with a Giant Bomb Wiki ID.
      }
    SPARQL

    return sparql
  end
end
