namespace 'import:wikidata' do
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

    progress_bar = ProgressBar.create(
      total: rows.length,
      format: formatting
    )

    PgSearch.disable_multisearch do
      rows.each do |row|
        progress_bar.increment
        url = row.to_h[:item].to_s
        wikidata_id = url.gsub('http://www.wikidata.org/entity/', '')

        wikidata_json = WikidataHelper.get_claims(
          entity: wikidata_id
        )

        wikidata_label = WikidataHelper.get_labels(
          ids: wikidata_id,
          languages: 'en'
        )

        label = wikidata_label.dig(wikidata_id, 'labels', 'en', 'value')
        next if label.nil?

        game_hash = { wikidata_id: wikidata_id.delete('Q'), name: label }

        # Create attributes for each property.
        properties.keys.each do |key|
          game_hash[key] = []
        end

        # Fill the game_hash's attributes with data from the Wikidata JSON.
        properties.each do |name, property|
          next if wikidata_json[property].nil?

          wikidata_json[property].each do |snak|
            game_hash[name] << snak.dig('mainsnak', 'datavalue', 'value', 'numeric-id')
          end

          # In the rare case of duplicate Wikidata IDs for a given property, strip them out.
          game_hash[name].uniq!
        end

        pcgamingwiki_id = wikidata_json.dig('P6337')&.first&.dig('mainsnak', 'datavalue', 'value')
        steam_app_id = wikidata_json.dig('P1733')&.first&.dig('mainsnak', 'datavalue', 'value')

        hash = {
          name: game_hash[:name],
          wikidata_id: game_hash[:wikidata_id]
        }

        hash[:pcgamingwiki_id] = pcgamingwiki_id unless pcgamingwiki_id.nil?
        hash[:steam_app_id] = steam_app_id unless steam_app_id.nil?

        game = Game.create!(hash)

        keys = []
        game_hash.keys.each do |key|
          next if key == :name || key == :wikidata_id || game_hash[key].nil? || game_hash[key] == []

          keys << key
        end

        if keys.include?(:developers)
          puts 'Adding developers.' if ENV['DEBUG']
          game_hash[:developers].each do |developer_id|
            company = Company.find_by(wikidata_id: developer_id)
            puts company.inspect if ENV['DEBUG']
            next if company.nil?

            GameDeveloper.create!(
              game_id: game.id,
              company_id: company.id
            )
          end
        end

        if keys.include?(:publishers)
          puts 'Adding publishers.' if ENV['DEBUG']
          game_hash[:publishers].each do |publisher_id|
            company = Company.find_by(wikidata_id: publisher_id)
            puts company.inspect if ENV['DEBUG']
            next if company.nil?

            GamePublisher.create!(
              game_id: game.id,
              company_id: company.id
            )
          end
        end

        if keys.include?(:platforms)
          puts 'Adding platforms.' if ENV['DEBUG']
          game_hash[:platforms].each do |platform_id|
            platform = Platform.find_by(wikidata_id: platform_id)
            puts platform.inspect if ENV['DEBUG']
            next if platform.nil?

            GamePlatform.create!(
              game_id: game.id,
              platform_id: platform.id
            )
          end
        end

        if keys.include?(:engines)
          puts 'Adding engines.' if ENV['DEBUG']
          game_hash[:engines].each do |engine_id|
            engine = Engine.find_by(wikidata_id: engine_id)
            puts engine.inspect if ENV['DEBUG']
            next if engine.nil?

            GameEngine.create!(
              game_id: game.id,
              engine_id: engine.id
            )
          end
        end

        if keys.include?(:genres)
          puts 'Adding genres.' if ENV['DEBUG']
          game_hash[:genres].each do |genre_id|
            genre = Genre.find_by(wikidata_id: genre_id)
            puts genre.inspect if ENV['DEBUG']
            next if genre.nil?

            GameGenre.create!(
              game_id: game.id,
              genre_id: genre.id
            )
          end
        end

        if keys.include?(:series)
          puts 'Adding series.' if ENV['DEBUG']

          series = Series.find_by(wikidata_id: game_hash[:series].first)
          puts series.inspect if ENV['DEBUG']
          next if series.nil?

          Game.update(
            game.id,
            { series_id: series.id }
          )
        end
      end
    end

    puts "There are now #{Game.count} games in the database."
    puts "Run 'bundle exec rake pg_search:multisearch:rebuild[Games]' to have pg_search rebuild its multisearch index."
  end

  # The SPARQL query for getting all video games on Wikidata.
  def games_query
    sparql = <<-SPARQL
      SELECT ?item WHERE {
        ?item wdt:P31 wd:Q7889. # Instances of video games.
      }
    SPARQL

    return sparql
  end

  # Return the formatting to use for the progress bar.
  def formatting
    return "\e[0;32m%c/%C |%b>%i| %e\e[0m"
  end
end
