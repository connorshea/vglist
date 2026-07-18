# frozen_string_literal: true

# rubocop:disable Rails/TimeZone
ADULT_GAME_BLOCKLIST_TERMS = ['hentai', 'futanari', 'porn', 'eroge'].freeze

# Number of games to hydrate per SPARQL round-trip. Bigger chunks mean fewer
# round-trips (and less of the per-query pacing sleep) on a full import, at the
# cost of larger VALUES clauses and result sets per query. Queries go over POST
# (see WikidataSparql.client), so this isn't bounded by a GET URL-length limit.
GAME_HYDRATION_CHUNK_SIZE = 500

# The multi-valued Wikidata properties we import per game, mapped to their
# property IDs. Fetched together in a single UNION query (see
# property_values_query) rather than one round-trip each.
GAME_PROPERTIES = {
  developers: 'P178',
  publishers: 'P123',
  platforms: 'P400',
  genres: 'P136',
  series: 'P179',
  engines: 'P408'
}.freeze

namespace 'import:wikidata' do
  require 'wikidata_sparql'

  desc "Import games from Wikidata"
  task games: :environment do
    puts "Importing games from Wikidata..."

    # Driver query: every video game with an en/mul label. Returns only the
    # item IDs — everything else is hydrated in bulk below, per chunk.
    driver_rows = WikidataSparql.query(games_query)

    # Everything we need to filter/hydrate against, loaded once. Sets give O(1)
    # membership checks against the ~1M driver rows.
    existing_wikidata_ids = Game.where.not(wikidata_id: nil).pluck(:wikidata_id).to_set
    blocklisted_wikidata_ids = WikidataBlocklist.pluck(:wikidata_id).to_set
    blocklisted_steam_app_ids = SteamBlocklist.pluck(:steam_app_id).to_set

    # Maps of Wikidata IDs to vglist IDs for platforms, engines, and genres, to
    # avoid tons of extra queries later.
    vglist_engines = Engine.all.pluck(:wikidata_id, :id).to_h
    vglist_platforms = Platform.all.pluck(:wikidata_id, :id).to_h
    vglist_genres = Genre.all.pluck(:wikidata_id, :id).to_h

    # Numeric Wikidata IDs of games that aren't already in the database and
    # aren't blocklisted. These are the only games we hydrate and create.
    new_wikidata_ids = driver_rows.filter_map do |row|
      wikidata_id = row.to_h[:item].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i
      next if existing_wikidata_ids.include?(wikidata_id) || blocklisted_wikidata_ids.include?(wikidata_id)

      wikidata_id
    end.uniq

    puts "Found #{new_wikidata_ids.length} new games to import."

    progress_bar = ProgressBar.create(
      total: new_wikidata_ids.length,
      format: formatting
    )

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    PgSearch.disable_multisearch do
      # Hydrate and create games one chunk at a time to keep memory and query
      # size bounded on a full import.
      new_wikidata_ids.each_slice(GAME_HYDRATION_CHUNK_SIZE) do |chunk|
        # Bulk-fetch everything for this chunk from Wikidata over SPARQL, rather
        # than making per-game REST API calls.
        details = fetch_game_details(chunk)
        release_dates = fetch_release_dates(chunk)
        props_by_game = fetch_property_values(chunk)

        chunk.each do |wikidata_id|
          progress_bar.increment

          detail = details[wikidata_id]
          label = detail&.dig(:label)
          if label.nil?
            progress_bar.log "No label. Skipping."
            next
          end

          downcased_label = label.downcase

          if downcased_label.include?('playtest') || ADULT_GAME_BLOCKLIST_TERMS.any? { |term| downcased_label.include?(term) }
            progress_bar.log "#{label}: Blocked name. Skipping."
            next
          end

          # Numeric Wikidata IDs for each of this game's properties, defaulting
          # to an empty array when the game has none of a given property.
          game_props = GAME_PROPERTIES.keys.index_with { |key| props_by_game[key][wikidata_id] || [] }

          hash = {
            name: label,
            wikidata_id: wikidata_id
          }

          hash[:pcgamingwiki_id] = detail[:pcgamingwiki_id] unless detail[:pcgamingwiki_id].nil?
          hash[:epic_games_store_id] = detail[:epic_games_store_id] unless detail[:epic_games_store_id].nil?
          hash[:gog_id] = detail[:gog_id] unless detail[:gog_id].nil?
          hash[:igdb_id] = detail[:igdb_id] unless detail[:igdb_id].nil?
          hash[:mobygames_id] = detail[:mobygames_id] unless detail[:mobygames_id].nil?
          hash[:giantbomb_id] = detail[:giantbomb_id] unless detail[:giantbomb_id].nil?

          release_date = release_dates[wikidata_id]
          hash[:release_date] = release_date unless release_date.nil?

          begin
            game = Game.create!(hash)
            progress_bar.log "Created #{hash[:name]}."
          rescue ActiveRecord::RecordInvalid => e
            progress_bar.log "Invalid: #{hash[:name].ljust(30)} | #{e}"
            next
          end

          steam_app_id = detail[:steam_app_id]
          unless steam_app_id.nil? || blocklisted_steam_app_ids.include?(steam_app_id.to_i)
            progress_bar.log 'Adding Steam App ID.' if ENV['DEBUG']
            begin
              SteamAppId.create!(
                game_id: game.id,
                app_id: steam_app_id
              )
            rescue ActiveRecord::RecordInvalid => e
              progress_bar.log "Invalid Steam AppID: #{hash[:name].ljust(30)} | #{e}"
            end
          end

          company_wikidata_ids = (game_props[:developers] + game_props[:publishers]).uniq
          unless company_wikidata_ids.empty?
            companies = Company.where(wikidata_id: company_wikidata_ids).pluck(:wikidata_id, :id).to_h

            progress_bar.log 'Adding developers.' if ENV['DEBUG']
            game_props[:developers].each do |developer_wikidata_id|
              company_id = companies[developer_wikidata_id]
              next if company_id.nil?

              GameDeveloper.create!(game_id: game.id, company_id: company_id)
            end

            progress_bar.log 'Adding publishers.' if ENV['DEBUG']
            game_props[:publishers].each do |publisher_wikidata_id|
              company_id = companies[publisher_wikidata_id]
              next if company_id.nil?

              GamePublisher.create!(game_id: game.id, company_id: company_id)
            end
          end

          progress_bar.log 'Adding platforms.' if ENV['DEBUG']
          game_props[:platforms].each do |platform_wikidata_id|
            platform_id = vglist_platforms[platform_wikidata_id]
            GamePlatform.create!(game_id: game.id, platform_id: platform_id) unless platform_id.nil?
          end

          progress_bar.log 'Adding engines.' if ENV['DEBUG']
          game_props[:engines].each do |engine_wikidata_id|
            engine_id = vglist_engines[engine_wikidata_id]
            GameEngine.create!(game_id: game.id, engine_id: engine_id) unless engine_id.nil?
          end

          progress_bar.log 'Adding genres.' if ENV['DEBUG']
          game_props[:genres].each do |genre_wikidata_id|
            genre_id = vglist_genres[genre_wikidata_id]
            GameGenre.create!(game_id: game.id, genre_id: genre_id) unless genre_id.nil?
          end

          next if game_props[:series].empty?

          progress_bar.log 'Adding series.' if ENV['DEBUG']
          series = Series.find_by(wikidata_id: game_props[:series].first)
          progress_bar.log series.inspect if ENV['DEBUG']
          next if series.nil?

          game.update!(series_id: series.id)
        end
      end
    end

    progress_bar.finish unless progress_bar.finished?

    puts 'Rebuilding search index...'
    PgSearch::Multisearch.rebuild(Game)

    puts "There are now #{Game.count} games in the database."
  end

  desc "Import release dates for games from Wikidata"
  task 'games:release_dates': :environment do
    puts "Importing game release dates from Wikidata..."

    # Games in the database that have a Wikidata ID but no release date yet.
    wikidata_ids = Game.where.not(wikidata_id: nil).where(release_date: nil).pluck(:wikidata_id)

    # Set whodunnit to 'system' for any audited changes made by this Rake task.
    PaperTrail.request.whodunnit = 'system'

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    progress_bar = ProgressBar.create(
      total: wikidata_ids.length,
      format: formatting
    )

    wikidata_ids.each_slice(GAME_HYDRATION_CHUNK_SIZE) do |chunk|
      release_dates = fetch_release_dates(chunk)
      games = Game.where(wikidata_id: chunk).index_by(&:wikidata_id)

      chunk.each do |wikidata_id|
        progress_bar.increment

        game = games[wikidata_id]
        next if game.nil?

        release_date = release_dates[wikidata_id]
        if release_date.nil?
          progress_bar.log "No release dates found for #{game.name}."
          next
        end

        begin
          game.update!(release_date: release_date)
          progress_bar.log "Added release date for #{game.name}."
        rescue ActiveRecord::RecordInvalid => e
          progress_bar.log "Invalid: #{game.name.ljust(30)} | #{e}"
          next
        end
      end
    end

    progress_bar.finish unless progress_bar.finished?
  end

  # The SPARQL query for getting all video games with English or mul labels on Wikidata.
  def games_query
    <<-SPARQL
      SELECT ?item WHERE {
        VALUES ?videoGameTypes { wd:Q7889 wd:Q21125433 }.
        ?item wdt:P31 ?videoGameTypes; # Instances of 'video games' or 'free or open source video games'.
              rdfs:label ?label .
          FILTER(lang(?label) = "en" || lang(?label) = "mul") # with a mul or en label
      }
      GROUP BY ?item
      HAVING (COUNT(?label) > 0)
    SPARQL
  end

  # Bulk-fetch labels and single-valued external store IDs for a chunk of games.
  #
  # @param [Array<Integer>] wikidata_ids Numeric Wikidata IDs, e.g. [7889, 21125433].
  # @return [Hash{Integer => Hash}] Keyed by numeric Wikidata ID.
  def fetch_game_details(wikidata_ids)
    rows = WikidataSparql.query(game_details_query(wikidata_ids))

    rows.each_with_object({}) do |row, details|
      row = row.to_h
      wikidata_id = row[:item].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i

      details[wikidata_id] = {
        # Prefer the English label, falling back to the 'mul' (multilingual) one.
        label: (row[:en] || row[:mul])&.to_s,
        steam_app_id: row[:steamAppId]&.to_s,
        pcgamingwiki_id: row[:pcgamingwikiId]&.to_s,
        epic_games_store_id: row[:epicGamesStoreId]&.to_s,
        # Remove the 'game/' prefix from GOG.com IDs.
        gog_id: row[:gogId]&.to_s&.gsub('game/', ''),
        igdb_id: row[:igdbId]&.to_s,
        mobygames_id: row[:mobygamesId]&.to_s,
        giantbomb_id: row[:giantbombId]&.to_s
      }
    end
  end

  # Bulk-fetch the numeric Wikidata IDs of every multi-valued property in
  # GAME_PROPERTIES for a chunk of games, in a single UNION query.
  #
  # @param [Array<Integer>] wikidata_ids Numeric Wikidata IDs.
  # @return [Hash{Symbol => Hash{Integer => Array<Integer>}}] Keyed by property
  #   name (:platforms, :developers, ...), then by numeric Wikidata game ID.
  def fetch_property_values(wikidata_ids)
    rows = WikidataSparql.query(property_values_query(wikidata_ids))

    values = GAME_PROPERTIES.keys.index_with { {} }
    rows.each do |row|
      row = row.to_h
      key = row[:propType].to_s.to_sym
      next unless values.key?(key)

      wikidata_id = row[:item].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i
      values[key][wikidata_id] = row[:props].to_s.split(', ').map { |prop| prop.delete('Q').to_i }
    end
    values
  end

  # Bulk-fetch the earliest day-precision release date for a chunk of games.
  #
  # @param [Array<Integer>] wikidata_ids Numeric Wikidata IDs.
  # @return [Hash{Integer => Date}] Keyed by numeric Wikidata ID.
  def fetch_release_dates(wikidata_ids)
    rows = WikidataSparql.query(release_dates_query(wikidata_ids))

    dates = Hash.new { |hash, key| hash[key] = [] }
    rows.each do |row|
      row = row.to_h
      wikidata_id = row[:item].to_s.gsub('http://www.wikidata.org/entity/Q', '').to_i
      parsed = parse_release_date(row[:date])
      dates[wikidata_id] << parsed unless parsed.nil?
    end

    dates.transform_values(&:min)
  end

  # Parse a single Wikidata timestamp into a Date, or nil if it's invalid.
  def parse_release_date(time)
    return nil if time.nil?

    Time.parse(time.to_s).to_date
  rescue ArgumentError
    nil
  end

  # SPARQL for a chunk's labels and single-valued external store IDs. Every
  # property is OPTIONAL and collapsed with SAMPLE so each game yields one row.
  def game_details_query(wikidata_ids)
    <<-SPARQL
      SELECT ?item
             (SAMPLE(?enLabel) AS ?en)
             (SAMPLE(?mulLabel) AS ?mul)
             (SAMPLE(?steam) AS ?steamAppId)
             (SAMPLE(?pcgw) AS ?pcgamingwikiId)
             (SAMPLE(?epic) AS ?epicGamesStoreId)
             (SAMPLE(?gog) AS ?gogId)
             (SAMPLE(?igdb) AS ?igdbId)
             (SAMPLE(?mobygames) AS ?mobygamesId)
             (SAMPLE(?giantbomb) AS ?giantbombId)
      WHERE {
        #{values_clause(wikidata_ids)}
        OPTIONAL { ?item rdfs:label ?enLabel. FILTER(lang(?enLabel) = "en") }
        OPTIONAL { ?item rdfs:label ?mulLabel. FILTER(lang(?mulLabel) = "mul") }
        OPTIONAL { ?item wdt:P1733 ?steam. } # Steam App ID
        OPTIONAL { ?item wdt:P6337 ?pcgw. } # PCGamingWiki ID
        OPTIONAL { ?item wdt:P6278 ?epic. } # Epic Games Store ID
        OPTIONAL { ?item wdt:P2725 ?gog. } # GOG.com ID
        OPTIONAL { ?item wdt:P5794 ?igdb. } # IGDB ID
        OPTIONAL { ?item wdt:P11688 ?mobygames. } # MobyGames ID
        OPTIONAL { ?item wdt:P5247 ?giantbomb. } # Giant Bomb ID
      }
      GROUP BY ?item
    SPARQL
  end

  # SPARQL for a chunk's values of every multi-valued property in
  # GAME_PROPERTIES, concatenated per game and tagged with the property name.
  # Each property is its own UNION branch: UNION concatenates rows rather than
  # joining them, so a game's platforms and genres don't Cartesian-multiply the
  # way they would as sibling triples in one pattern. Based on the query used for
  # https://www.wikidata.org/wiki/Wikidata:WikiProject_Video_games/Statistics/Platform
  def property_values_query(wikidata_ids)
    union_branches = GAME_PROPERTIES.map do |name, property|
      %({ ?item wdt:#{property} ?p1. BIND("#{name}" AS ?propType) })
    end.join("\n        UNION ")

    <<-SPARQL
      SELECT ?item ?propType (GROUP_CONCAT(DISTINCT ?prop; separator=", ") AS ?props) WHERE {
        #{values_clause(wikidata_ids)}
        #{union_branches}
        BIND(strafter(str(?p1), "http://www.wikidata.org/entity/") AS ?prop)
      }
      GROUP BY ?item ?propType
    SPARQL
  end

  # SPARQL for a chunk's day-precision, best-rank release dates. A game may have
  # more than one; the earliest is chosen in Ruby.
  def release_dates_query(wikidata_ids)
    <<-SPARQL
      SELECT ?item ?date WHERE {
        #{values_clause(wikidata_ids)}
        ?item p:P577 ?releaseDateStatement. # publication date
        ?releaseDateStatement a wikibase:BestRank; # ... of best rank (instead of wdt:P577)
            psv:P577 ?releaseDateValue.
        ?releaseDateValue wikibase:timePrecision 11; # Precision is "day" (encoded as integer 11)
            wikibase:timeValue ?date.
      }
    SPARQL
  end

  # A `VALUES ?item { wd:Q1 wd:Q2 ... }` clause binding a chunk of games.
  def values_clause(wikidata_ids)
    "VALUES ?item { #{wikidata_ids.map { |id| "wd:Q#{id}" }.join(' ')} }"
  end

  # Return the formatting to use for the progress bar.
  def formatting
    "\e[0;32m%c/%C |%b>%i| %e\e[0m"
  end
end
# rubocop:enable Rails/TimeZone
