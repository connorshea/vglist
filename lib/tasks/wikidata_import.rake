namespace :wikidata_import do
  require 'sparql/client'

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

      # puts "#{wikidata_id}: #{row[:count].to_s}"

      wikidata_ids << wikidata_id
    end

    puts wikidata_ids.inspect


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
