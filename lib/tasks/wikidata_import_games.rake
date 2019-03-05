namespace :wikidata_import do
  require 'sparql/client'
  require 'wikidata_helper'

  desc "Import games from Wikidata"
  task games: :environment do
    # Abort if there are already records in the database.
    # In the future we may want to be able to re-import from Wikidata,
    # but for now we can just fail for any attempted imports after the first run.
    abort("You can't import games if there are already games in the database.") if Game.count > 0

    puts "Importing games from Wikidata..."
    client = SPARQL::Client.new("https://query.wikidata.org/sparql", method: :get)

    rows = []
    rows.concat(client.query(games_query))

    properties = {
      developers: 'P178',
      publishers: 'P123',
      platforms: 'P400',
      genres: 'P136',
      series: 'P179',
      engines: 'P408'
    }

    rows.each do |row|
      url = row.to_h[:item].to_s
      wikidata_id = url.gsub('http://www.wikidata.org/entity/', '')

      return_value = WikidataHelper.get_claims(
        entity: wikidata_id
      )

      game = { wikidata_id: wikidata_id }

      # Create attributes for each property.
      properties.keys.each do |key|
        game[key] = []
      end

      # Fill the game hash's attributes with data from the Wikidata JSON.
      properties.each do |name, property|
        next if return_value[property].nil?
        return_value[property].each do |snak|
          game[name] << snak.dig('mainsnak', 'datavalue', 'value', 'numeric-id')
        end
      end

      puts game.inspect
      # puts JSON.pretty_generate(return_value)
    end

    puts "There are now #{Game.count} games in the database."
  end

  def games_query
    sparql = <<-SPARQL
      SELECT ?item WHERE {
        ?item wdt:P31 wd:Q7889. # Instances of video games.
      } LIMIT 10
    SPARQL

    return sparql
  end
end
