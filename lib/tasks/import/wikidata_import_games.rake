# typed: ignore
# rubocop:disable Rails/TimeZone
namespace 'import:wikidata' do
  require 'sparql/client'
  require 'wikidata_helper'

  desc "Import games from Wikidata"
  task games: :environment do
    puts "Importing games from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(games_query))

    # Get every game in the database that has a Wikidata ID.
    games = Game.where.not(wikidata_id: nil)

    existing_wikidata_ids = games.map { |game| game[:wikidata_id] }
    blocklisted_ids = WikidataBlocklist.pluck(:wikidata_id)

    # Filter to wikidata items that don't already exist in the database.
    # Also filter out blocklisted Wikidata items.
    rows = rows.reject do |row|
      url = row.to_h[:item].to_s
      wikidata_id = url.gsub('http://www.wikidata.org/entity/Q', '')
      existing_wikidata_ids.include?(wikidata_id.to_i) || blocklisted_ids.include?(wikidata_id.to_i)
    end

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

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

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
        if label.nil?
          puts "No label. Skipping."
          next
        end

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
        epic_games_store_id = wikidata_json.dig('P6278')&.first&.dig('mainsnak', 'datavalue', 'value')
        # Remove the 'game/' prefix from the GOG.com IDs.
        gog_id = wikidata_json.dig('P2725')&.first&.dig('mainsnak', 'datavalue', 'value')&.gsub('game/', '')
        mobygames_id = wikidata_json.dig('P1933')&.first&.dig('mainsnak', 'datavalue', 'value')
        giantbomb_id = wikidata_json.dig('P5247')&.first&.dig('mainsnak', 'datavalue', 'value')

        release_dates = wikidata_json.dig('P577')&.map { |date| date.dig('mainsnak', 'datavalue', 'value', 'time') }
        release_dates&.map! do |time|
          if time.nil?
            nil
          else
            begin
              Time.parse(time).to_date
            rescue ArgumentError
              nil
            end
          end
        end
        # Set release date equal to nil, or the earliest release date if
        # all of the release dates above resolved to a proper date. It's done
        # this way to prevent bad release dates from being used if Wikidata
        # returns a date like "June 2019", which is represented as "2019-06-00",
        # an invalid date.
        release_date = nil
        release_date = release_dates&.min unless release_dates&.any? { |date| date.nil? }

        hash = {
          name: game_hash[:name],
          wikidata_id: game_hash[:wikidata_id]
        }

        hash[:pcgamingwiki_id] = pcgamingwiki_id unless pcgamingwiki_id.nil?
        hash[:epic_games_store_id] = epic_games_store_id unless epic_games_store_id.nil?
        hash[:gog_id] = gog_id unless gog_id.nil?
        hash[:mobygames_id] = mobygames_id unless mobygames_id.nil?
        hash[:giantbomb_id] = giantbomb_id unless giantbomb_id.nil?
        hash[:release_date] = release_date unless release_date.nil?

        begin
          game = Game.create!(hash)
          puts "Created #{hash[:name]}."
        rescue ActiveRecord::RecordInvalid => e
          puts "Record Invalid (#{hash[:name]}): #{e}"
          next
        end

        keys = []
        game_hash.keys.each do |key|
          next if key == :name || key == :wikidata_id || game_hash[key].nil? || game_hash[key] == []

          keys << key
        end

        unless steam_app_id.nil?
          puts 'Adding Steam App ID.' if ENV['DEBUG']
          SteamAppId.create(
            game_id: game.id,
            app_id: steam_app_id
          )
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

  desc "Import release dates for games from Wikidata"
  task 'games:release_dates': :environment do
    puts "Importing game release dates from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'vglist Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(games_query))

    # Get every game in the database that has a Wikidata ID and no release date.
    games = Game.where.not(wikidata_id: nil).where(release_date: nil)

    existing_wikidata_ids = games.map { |game| game[:wikidata_id] }

    # Filter to wikidata items that already exist in the database.
    rows = rows.select do |row|
      url = row.to_h[:item].to_s
      wikidata_id = url.gsub('http://www.wikidata.org/entity/Q', '')
      existing_wikidata_ids.include?(wikidata_id.to_i)
    end

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    progress_bar = ProgressBar.create(
      total: rows.length,
      format: formatting
    )

    rows.each do |row|
      progress_bar.increment

      url = row.to_h[:item].to_s
      wikidata_id = url.gsub('http://www.wikidata.org/entity/', '')
      wikidata_id_no_q = url.gsub('http://www.wikidata.org/entity/Q', '')

      game = Game.find_by(wikidata_id: wikidata_id_no_q.to_i)

      wikidata_json = WikidataHelper.get_claims(
        entity: wikidata_id
      )

      if wikidata_json['P577'].nil?
        progress_bar.log "No release dates found for #{game[:name]}."
        next
      end

      release_dates = []
      wikidata_json['P577'].each do |snak|
        release_date_hash = snak.dig('mainsnak', 'datavalue', 'value')
        # Catch the case where the release date is invalid. This happens
        # because Wikidata allows dates like "June 2019", so the API returns
        # bad data like '2019-06-00', which isn't a valid date. We just
        # skip these entirely to avoid bad data.
        begin
          release_dates << Time.parse(release_date_hash['time']).to_date unless release_date_hash.nil?
        rescue ArgumentError
          progress_bar.log "Bad datetime, skipping. (#{release_date_hash['time']})"
          # Break out of the loop to prevent incorrect release dates, in case a
          # game has a release date like "1985" and then a later, valid release
          # date. We'd rather just skip adding a release date altogether.
          break
        end
      end

      # Get earliest release date
      earliest_release_date = release_dates.min

      if earliest_release_date.nil?
        progress_bar.log "No release dates found for #{game[:name]}."
        next
      end

      begin
        game.update!(release_date: earliest_release_date)
        progress_bar.log "Added release date for #{game[:name]}."
      rescue ActiveRecord::RecordInvalid => e
        progress_bar.log "Record Invalid (#{game[:name]}): #{e}"
        next
      end
    end
  end

  # The SPARQL query for getting all video games with English labels on Wikidata.
  def games_query
    sparql = <<-SPARQL
      SELECT ?item WHERE {
        VALUES ?videoGameTypes { wd:Q7889 wd:Q21125433 }.
        ?item wdt:P31 ?videoGameTypes; # Instances of 'video games' or 'free or open source video games'.
              rdfs:label ?label filter(lang(?label) = "en"). # with a label
      }
    SPARQL

    return sparql
  end

  # Return the formatting to use for the progress bar.
  def formatting
    return "\e[0;32m%c/%C |%b>%i| %e\e[0m"
  end
end
# rubocop:enable Rails/TimeZone
