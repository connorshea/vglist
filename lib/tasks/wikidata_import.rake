namespace :wikidata_import do
  require 'sparql/client'
  require 'wikidata_helper'

  desc "Import game developers from Wikidata"
  task :developers do
    puts "Importing game developers from Wikidata..."

    endpoint = "https://query.wikidata.org/sparql"
    client = SPARQL::Client.new(endpoint, :method => :get)

    rows = []
    rows.concat(client.query(developers_query))
    wikidata_ids = []

    puts "Importing #{rows.length} developers."
    rows.each do |row|
      row = row.to_h
      # Skip if the Wikidata item ID is nil (as is the case with the first row).
      next unless row.key?(:item)
      wikidata_url = row[:item].to_s
      wikidata_id = wikidata_url.gsub('http://www.wikidata.org/entity/', '')

      wikidata_ids << wikidata_id
    end

    developers = []

    (wikidata_ids.length / 45).floor.times do |index|
      puts "index: #{index}"
      start_from = index * 45
      wikidata_labels = WikidataHelper.get_labels(
        ids: wikidata_ids[start_from..start_from+45],
        languages: 'en'
      )
      wikidata_labels.each do |id, wikidata_label|
        # Skip items with no labels or no English label.
        next unless wikidata_label.key?('labels')
        next unless wikidata_label['labels'].key?('en')
        name = wikidata_label['labels']['en']['value']
        wikidata_item = { wikidata_id: id, name: name }

        developers << wikidata_item
      end
    end

    puts developers.inspect
  end

  # Returns data for game developers sorted by number of games developed.
  # Query based off the query used for https://www.wikidata.org/wiki/Wikidata:WikiProject_Video_games/Statistics/Platform
  # The first row is the total count of games with no developers.
  def developers_query
    sparql = <<-SPARQL
      SELECT ?item (COUNT(?game) as ?count) WHERE {
        ?game wdt:P31 wd:Q7889. # Instance of video game
        OPTIONAL { ?game wdt:P178 ?item. }
      } GROUP BY ?item
      ORDER BY DESC(?count)
    SPARQL
  
    return sparql
  end
end
