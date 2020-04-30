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
          progress_bar.log "No label. Skipping."
          next
        end

        game_hash = { wikidata_id: wikidata_id.delete('Q'), name: label }

        # Create attributes for each property.
        properties.each_key do |key|
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

        release_date = wikidata_json.dig('P577')&.map do |date|
          date.dig('mainsnak', 'datavalue', 'value', 'time')
        end&.reject(&:nil?)&.map do |time|
          Time.parse(time).to_date
                       rescue ArgumentError
                         nil
        end&.reject(&:nil?)&.min

        hash = {
          name: game_hash[:name],
          wikidata_id: game_hash[:wikidata_id],
          pcgamingwiki_id: wikidata_json.dig('P6337')&.first&.dig('mainsnak', 'datavalue', 'value'),
          epic_games_store_id: wikidata_json.dig('P6278')&.first&.dig('mainsnak', 'datavalue', 'value'),
          # Remove the 'game/' prefix from the GOG.com IDs.
          gog_id: wikidata_json.dig('P2725')&.first&.dig('mainsnak', 'datavalue', 'value')&.gsub('game/', ''),
          mobygames_id: wikidata_json.dig('P1933')&.first&.dig('mainsnak', 'datavalue', 'value'),
          giantbomb_id: wikidata_json.dig('P5247')&.first&.dig('mainsnak', 'datavalue', 'value'),
          release_date: release_date
        }.reject { |_, v| v.nil? }

        begin
          game = Game.create!(hash)
          progress_bar.log "Created #{hash[:name]}."
        rescue ActiveRecord::RecordInvalid => e
          progress_bar.log "Record Invalid (#{hash[:name]}): #{e}"
          next
        end

        keys = []
        game_hash.each_key do |key|
          next if key == :name || key == :wikidata_id || game_hash[key].nil? || game_hash[key] == []

          keys << key
        end

        steam_app_id = wikidata_json.dig('P1733')&.first&.dig('mainsnak', 'datavalue', 'value')
        unless steam_app_id.nil?
          progress_bar.log 'Adding Steam App ID.' if ENV['DEBUG']
          SteamAppId.create(
            game_id: game.id,
            app_id: steam_app_id
          )
        end

        if keys.include?(:developers)
          progress_bar.log 'Adding developers.' if ENV['DEBUG']
          Company.where(wikidata_id: game_hash[:developers]).pluck(:id).map do |company_id|
            { company_id: company_id, game_id: game.id }
          end.tap { |attrs| GameDeveloper.insert_all(attrs) if attrs.any? }
        end

        if keys.include?(:publishers)
          progress_bar.log 'Adding publishers.' if ENV['DEBUG']
          Company.where(wikidata_id: game_hash[:publishers]).pluck(:id).map do |publisher_id|
            { company_id: publisher_id, game_id: game.id }
          end.tap { |attrs| GamePublisher.insert_all(attrs) if attrs.any? }
        end

        if keys.include?(:platforms)
          progress_bar.log 'Adding platforms.' if ENV['DEBUG']
          Platform.where(wikidata_id: game_hash[:platforms]).pluck(:id).map do |platform_id|
            { platform_id: platform_id, game_id: game_id }
          end.tap { |attrs| GamePlatform.insert_all(attrs) if attrs.any? }
        end

        if keys.include?(:engines)
          progress_bar.log 'Adding engines.' if ENV['DEBUG']
          Engine.where(wikidata_id: game_hash[:engines]).pluck(:id).map do |engine_id|
            { engine_id: engine_id, game_id: game.id }
          end.tap { |attrs| GameEngine.insert_all(attrs) if attrs.any? }
        end

        if keys.include?(:genres)
          progress_bar.log 'Adding genres.' if ENV['DEBUG']
          Genre.where(wikidata_id: game_hash[:genres]).pluck(:id).map do |genre_id|
            { genre_id: genre_id, game_id: game.id }
          end.tap { |attrs| GameGenre.insert_all(attrs) if attrs.any? }
        end

        if keys.include?(:series)
          progress_bar.log 'Adding series.' if ENV['DEBUG']

          series = Series.find_by(wikidata_id: game_hash[:series].first)
          progress_bar.log series.inspect if ENV['DEBUG']
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
    <<-SPARQL
      SELECT ?item WHERE {
        VALUES ?videoGameTypes { wd:Q7889 wd:Q21125433 }.
        ?item wdt:P31 ?videoGameTypes; # Instances of 'video games' or 'free or open source video games'.
              rdfs:label ?label filter(lang(?label) = "en"). # with a label
      }
    SPARQL
  end

  # Return the formatting to use for the progress bar.
  def formatting
    "\e[0;32m%c/%C |%b>%i| %e\e[0m"
  end
end
# rubocop:enable Rails/TimeZone
