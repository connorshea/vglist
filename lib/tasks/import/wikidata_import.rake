# frozen_string_literal: true

# Number of items to fetch labels for per SPARQL round-trip. Kept small enough
# that the VALUES clause fits comfortably inside a GET query string.
LABEL_HYDRATION_CHUNK_SIZE = 200

namespace 'import:wikidata' do
  require 'wikidata_sparql'
  require 'ruby-progressbar'

  desc "Import game developers and publishers from Wikidata"
  task companies: :environment do
    puts "Importing game developers and publishers from Wikidata..."

    rows = get_rows(developers_query)
    rows.concat(get_rows(publishers_query))

    puts "Importing up to #{rows.length} companies."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    companies = wikidata_item_filter(rows: rows, progress_bar: progress_bar_for_filter)
    companies.uniq! { |company| company&.dig(:wikidata_id) }

    # Filter companies that are already represented in the vglist database.
    wikidata_ids_in_db = Company.where.not(wikidata_id: nil).pluck(:wikidata_id)
    companies = companies.reject { |company| wikidata_ids_in_db.include?(company[:wikidata_id].delete('Q').to_i) }

    puts
    puts "Found #{companies.length} companies."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: companies.length,
      format: formatting
    )

    # Set whodunnit to 'system' when creating records.
    PaperTrail.request(whodunnit: 'system') do
      PgSearch.disable_multisearch do
        companies.each do |company|
          Company.create!(
            name: company[:name],
            wikidata_id: company[:wikidata_id].delete('Q')
          )
          progress_bar_for_import.increment
        end
      end
    end
    progress_bar_for_import.finish unless progress_bar_for_import.finished?

    puts 'Rebuilding search index...'
    PgSearch::Multisearch.rebuild(Company)

    puts "There are now #{Company.count} companies in the database."
  end

  desc "Import game platforms from Wikidata"
  task platforms: :environment do
    puts "Importing game platforms from Wikidata..."

    rows = get_rows(platforms_query)

    puts "Importing up to #{rows.length} platforms."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    platforms = wikidata_item_filter(rows: rows, count_limit: 80, progress_bar: progress_bar_for_filter)
    platforms.uniq! { |platform| platform&.dig(:wikidata_id) }

    # Filter platforms that are already represented in the vglist database.
    wikidata_ids_in_db = Platform.where.not(wikidata_id: nil).pluck(:wikidata_id)
    platforms = platforms.reject { |platform| wikidata_ids_in_db.include?(platform[:wikidata_id].delete('Q').to_i) }

    puts
    puts "Found #{platforms.length} platforms."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: platforms.length,
      format: formatting
    )

    # Set whodunnit to 'system' when creating records.
    PaperTrail.request(whodunnit: 'system') do
      PgSearch.disable_multisearch do
        platforms.each do |platform|
          Platform.create!(
            name: platform[:name],
            wikidata_id: platform[:wikidata_id].delete('Q')
          )
          progress_bar_for_import.increment
        end
      end
    end
    progress_bar_for_import.finish unless progress_bar_for_import.finished?

    puts 'Rebuilding search index...'
    PgSearch::Multisearch.rebuild(Platform)

    puts "There are now #{Platform.count} platforms in the database."
  end

  desc "Import game genres from Wikidata"
  task genres: :environment do
    puts "Importing game genres from Wikidata..."

    rows = get_rows(genres_query)

    puts "Importing up to #{rows.length} genres."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    genres = wikidata_item_filter(rows: rows, count_limit: 50, progress_bar: progress_bar_for_filter)
    genres.uniq! { |genre| genre&.dig(:wikidata_id) }

    # Filter genres that are already represented in the vglist database.
    wikidata_ids_in_db = Genre.where.not(wikidata_id: nil).pluck(:wikidata_id)
    genres = genres.reject { |genre| wikidata_ids_in_db.include?(genre[:wikidata_id].delete('Q').to_i) }

    progress_bar_for_filter.finish unless progress_bar_for_filter.finished?
    puts
    puts "Found #{genres.length} genres."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: genres.length,
      format: formatting
    )

    # Set whodunnit to 'system' when creating records.
    PaperTrail.request(whodunnit: 'system') do
      PgSearch.disable_multisearch do
        genres.each do |genre|
          Genre.create!(
            name: genre[:name],
            wikidata_id: genre[:wikidata_id].delete('Q')
          )
          progress_bar_for_import.increment
        end
      end
    end
    progress_bar_for_import.finish unless progress_bar_for_import.finished?

    puts 'Rebuilding search index...'
    PgSearch::Multisearch.rebuild(Genre)

    puts "There are now #{Genre.count} genres in the database."
  end

  desc "Import game series from Wikidata"
  task series: :environment do
    puts "Importing game series' from Wikidata..."

    rows = get_rows(series_query)

    puts "Importing up to #{rows.length} series'."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    series = wikidata_item_filter(rows: rows, count_limit: 1, progress_bar: progress_bar_for_filter)
    series.uniq! { |s| s&.dig(:wikidata_id) }

    # Filter series that are already represented in the vglist database.
    wikidata_ids_in_db = Series.where.not(wikidata_id: nil).pluck(:wikidata_id)
    series = series.reject { |srs| wikidata_ids_in_db.include?(srs[:wikidata_id].delete('Q').to_i) }

    puts
    puts "Found #{series.length} series'."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: series.length,
      format: formatting
    )

    # Set whodunnit to 'system' when creating records.
    PaperTrail.request(whodunnit: 'system') do
      PgSearch.disable_multisearch do
        series.each do |s|
          Series.create!(
            name: s[:name],
            wikidata_id: s[:wikidata_id].delete('Q')
          )
          progress_bar_for_import.increment
        end
      end
    end

    progress_bar_for_import.finish unless progress_bar_for_import.finished?

    puts 'Rebuilding search index...'
    PgSearch::Multisearch.rebuild(Series)

    puts "There are now #{Series.count} series in the database."
  end

  desc "Import game engines from Wikidata"
  task engines: :environment do
    puts "Importing game engines from Wikidata..."

    rows = get_rows(engines_query)

    puts "Importing up to #{rows.length} engines."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )

    # Limit logging in production to allow the progress bar to work.
    Rails.logger.level = 2 if Rails.env.production?

    engines = wikidata_item_filter(rows: rows, count_limit: 1, progress_bar: progress_bar_for_filter)
    engines.uniq! { |engine| engine&.dig(:wikidata_id) }

    # Filter engines that are already represented in the vglist database.
    wikidata_ids_in_db = Engine.where.not(wikidata_id: nil).pluck(:wikidata_id)
    engines = engines.reject { |engine| wikidata_ids_in_db.include?(engine[:wikidata_id].delete('Q').to_i) }

    puts
    puts "Found #{engines.length} engines."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: engines.length,
      format: formatting
    )

    # Set whodunnit to 'system' when creating records.
    PaperTrail.request(whodunnit: 'system') do
      PgSearch.disable_multisearch do
        engines.each do |engine|
          Engine.create!(
            name: engine[:name],
            wikidata_id: engine[:wikidata_id].delete('Q')
          )
          progress_bar_for_import.increment
        end
      end
    end

    progress_bar_for_import.finish unless progress_bar_for_import.finished?

    puts 'Rebuilding search index...'
    PgSearch::Multisearch.rebuild(Engine)

    puts "There are now #{Engine.count} engines in the database."
  end

  # Filter invalid items from a set of wikidata rows, and get better
  # data like labels.
  def wikidata_item_filter(rows:, count_limit: 0, progress_bar:)
    wikidata_ids = []

    rows.each do |row|
      row = row.to_h
      # Skip if the Wikidata item ID is nil.
      next unless row.key?(:item)
      # Skip if it's used in less than count_limit Wikidata items.
      # QLever returns the COUNT aggregate as a plain RDF::Literal (no integer
      # datatype), which doesn't define #to_i, so coerce through #to_s first.
      next if row[:count].to_s.to_i < count_limit

      wikidata_ids << row[:item].to_s.gsub('http://www.wikidata.org/entity/', '')
    end

    # Filter invalid data.
    wikidata_ids.select! { |id| id.start_with?('Q') }

    progress_bar.total = wikidata_ids.length

    # Hydrate labels in bulk over SPARQL rather than via the rate-limited REST
    # API, which was hitting 429s on large imports (e.g. ~14k companies).
    items = []
    wikidata_ids.each_slice(LABEL_HYDRATION_CHUNK_SIZE) do |chunk|
      labels = fetch_labels(chunk)
      chunk.each do |id|
        progress_bar.increment
        # Skip items with neither an English nor a 'mul' (multilingual) label.
        name = labels[id]
        items << { wikidata_id: id, name: name } unless name.nil?
      end
    end

    item_names = items.map { |item| item&.dig(:name) } if ENV["DEBUG"]
    puts item_names.inspect if ENV["DEBUG"]

    return items
  end

  # Bulk-fetch en/mul labels for a chunk of Wikidata items over SPARQL.
  #
  # @param [Array<String>] wikidata_ids Q-prefixed item IDs, e.g. ['Q123'].
  # @return [Hash{String => String}] Q-prefixed ID => label (English preferred,
  #   'mul' as fallback). Items with neither label are omitted.
  def fetch_labels(wikidata_ids)
    values_clause = wikidata_ids.map { |id| "wd:#{id}" }.join(' ')
    query = <<-SPARQL
      SELECT ?item (SAMPLE(?enLabel) AS ?en) (SAMPLE(?mulLabel) AS ?mul) WHERE {
        VALUES ?item { #{values_clause} }
        OPTIONAL { ?item rdfs:label ?enLabel. FILTER(lang(?enLabel) = "en") }
        OPTIONAL { ?item rdfs:label ?mulLabel. FILTER(lang(?mulLabel) = "mul") }
      }
      GROUP BY ?item
    SPARQL

    WikidataSparql.query(query).each_with_object({}) do |row, labels|
      row = row.to_h
      id = row[:item].to_s.gsub('http://www.wikidata.org/entity/', '')
      name = (row[:en] || row[:mul])&.to_s
      labels[id] = name unless name.nil?
    end
  end

  # Returns Wikidata items representing game developers.
  # https://www.wikidata.org/wiki/Property:P178
  def developers_query
    query('P178')
  end

  # Returns Wikidata items representing game publishers.
  # https://www.wikidata.org/wiki/Property:P123
  def publishers_query
    query('P123')
  end

  # Returns Wikidata items representing game platforms.
  # https://www.wikidata.org/wiki/Property:P400
  def platforms_query
    query('P400')
  end

  # Returns Wikidata items representing game genres.
  # https://www.wikidata.org/wiki/Property:P136
  def genres_query
    query('P136')
  end

  # Returns Wikidata items representing game series.
  # https://www.wikidata.org/wiki/Property:P179
  def series_query
    query('P179')
  end

  # Returns Wikidata items representing game engines.
  # https://www.wikidata.org/wiki/Property:P408
  def engines_query
    query('P408')
  end

  # Returns data for game properties sorted by associations, e.g. number of
  # games developed in the case of developers.
  # Query based off the query used for https://www.wikidata.org/wiki/Wikidata:WikiProject_Video_games/Statistics/Platform
  # The first row is the total count of games with no associations of this type.
  def query(property)
    sparql = <<-SPARQL
      SELECT ?item (COUNT(?game) as ?count) WHERE {
        ?game wdt:P31 wd:Q7889. # Instance of video game
        OPTIONAL { ?game wdt:#{property} ?item. }
      } GROUP BY ?item
      ORDER BY DESC(?count)
    SPARQL

    return sparql
  end

  # Return the formatting to use for the progress bar.
  def formatting
    return "\e[0;32m%c/%C |%b>%i| %e\e[0m"
  end

  # Convenience method for getting rows from SPARQL.
  def get_rows(query)
    WikidataSparql.query(query)
  end
end
