namespace 'import:wikidata' do
  require 'sparql/client'
  require 'wikidata_helper'
  require 'ruby-progressbar'

  desc "Import game developers and publishers from Wikidata"
  task companies: :environment do
    # Abort if there are already records in the database.
    # In the future we may want to be able to re-import from Wikidata,
    # but for now we can just fail for any attempted imports after the first run.
    abort("You can't import companies if there are already companies in the database.") if Company.count > 0

    puts "Importing game developers and publishers from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'VideoGameList Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(developers_query))
    rows.concat(client.query(publishers_query))

    puts "Importing up to #{rows.length} companies."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )
    companies = wikidata_item_filter(rows: rows, progress_bar: progress_bar_for_filter)
    companies.uniq! { |company| company&.dig(:wikidata_id) }
    puts
    puts "Found #{companies.length} companies."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: companies.length,
      format: formatting
    )

    PgSearch.disable_multisearch do
      companies.each do |company|
        Company.create!(
          name: company[:name],
          wikidata_id: company[:wikidata_id].delete('Q')
        )
        progress_bar_for_import.increment
      end
    end

    puts "There are now #{Company.count} companies in the database."
    puts "Run 'bundle exec rake pg_search:multisearch:rebuild[Companies]' to have pg_search rebuild its multisearch index."
  end

  desc "Import game platforms from Wikidata"
  task platforms: :environment do
    # Abort if there are already records in the database.
    # In the future we may want to be able to re-import from Wikidata,
    # but for now we can just fail for any attempted imports after the first run.
    abort("You can't import platforms if there are already platforms in the database.") if Platform.count > 0

    puts "Importing game platforms from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'VideoGameList Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(platforms_query))

    puts "Importing up to #{rows.length} platforms."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )
    platforms = wikidata_item_filter(rows: rows, count_limit: 80, progress_bar: progress_bar_for_filter)
    platforms.uniq! { |platform| platform&.dig(:wikidata_id) }
    puts
    puts "Found #{platforms.length} platforms."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: platforms.length,
      format: formatting
    )

    PgSearch.disable_multisearch do
      platforms.each do |platform|
        Platform.create!(
          name: platform[:name],
          wikidata_id: platform[:wikidata_id].delete('Q')
        )
        progress_bar_for_import.increment
      end
    end

    puts "There are now #{Platform.count} platforms in the database."
    puts "Run 'bundle exec rake pg_search:multisearch:rebuild[Platforms]' to have pg_search rebuild its multisearch index."
  end

  desc "Import game genres from Wikidata"
  task genres: :environment do
    # Abort if there are already records in the database.
    # In the future we may want to be able to re-import from Wikidata,
    # but for now we can just fail for any attempted imports after the first run.
    abort("You can't import genres if there are already genres in the database.") if Genre.count > 0

    puts "Importing game genres from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'VideoGameList Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(genres_query))

    puts "Importing up to #{rows.length} genres."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )
    genres = wikidata_item_filter(rows: rows, count_limit: 50, progress_bar: progress_bar_for_filter)
    genres.uniq! { |genre| genre&.dig(:wikidata_id) }
    progress_bar_for_filter.finish unless progress_bar_for_filter.finished?
    puts
    puts "Found #{genres.length} genres."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: genres.length,
      format: formatting
    )

    PgSearch.disable_multisearch do
      genres.each do |genre|
        Genre.create!(
          name: genre[:name],
          wikidata_id: genre[:wikidata_id].delete('Q')
        )
        progress_bar_for_import.increment
      end
    end

    puts "There are now #{Genre.count} genres in the database."
    puts "Run 'bundle exec rake pg_search:multisearch:rebuild[Genres]' to have pg_search rebuild its multisearch index."
  end

  desc "Import game series from Wikidata"
  task series: :environment do
    # Abort if there are already records in the database.
    # In the future we may want to be able to re-import from Wikidata,
    # but for now we can just fail for any attempted imports after the first run.
    abort("You can't import series if there are already series in the database.") if Series.count > 0

    puts "Importing game series' from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'VideoGameList Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(series_query))

    puts "Importing up to #{rows.length} series'."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )
    series = wikidata_item_filter(rows: rows, count_limit: 1, progress_bar: progress_bar_for_filter)
    series.uniq! { |s| s&.dig(:wikidata_id) }
    puts
    puts "Found #{series.length} series'."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: series.length,
      format: formatting
    )

    PgSearch.disable_multisearch do
      series.each do |s|
        Series.create!(
          name: s[:name],
          wikidata_id: s[:wikidata_id].delete('Q')
        )
        progress_bar_for_import.increment
      end
    end

    puts "There are now #{Series.count} series in the database."
    puts "Run 'bundle exec rake pg_search:multisearch:rebuild[Series]' to have pg_search rebuild its multisearch index."
  end

  desc "Import game engines from Wikidata"
  task engines: :environment do
    # Abort if there are already records in the database.
    # In the future we may want to be able to re-import from Wikidata,
    # but for now we can just fail for any attempted imports after the first run.
    abort("You can't import engines if there are already engines in the database.") if Engine.count > 0

    puts "Importing game engines from Wikidata..."
    client = SPARQL::Client.new(
      "https://query.wikidata.org/sparql",
      method: :get,
      headers: { 'User-Agent': 'VideoGameList Data Fetcher/1.0 (connor.james.shea@gmail.com) Ruby 2.6' }
    )

    rows = []
    rows.concat(client.query(engines_query))

    puts "Importing up to #{rows.length} engines."
    puts "Processing..."
    progress_bar_for_filter = ProgressBar.create(
      total: nil,
      format: formatting
    )
    engines = wikidata_item_filter(rows: rows, count_limit: 1, progress_bar: progress_bar_for_filter)
    engines.uniq! { |engine| engine&.dig(:wikidata_id) }
    puts
    puts "Found #{engines.length} engines."
    puts "Importing..."

    progress_bar_for_import = ProgressBar.create(
      total: engines.length,
      format: formatting
    )

    PgSearch.disable_multisearch do
      engines.each do |engine|
        Engine.create!(
          name: engine[:name],
          wikidata_id: engine[:wikidata_id].delete('Q')
        )
        progress_bar_for_import.increment
      end
    end

    puts "There are now #{Engine.count} engines in the database."
    puts "Run 'bundle exec rake pg_search:multisearch:rebuild[Engines]' to have pg_search rebuild its multisearch index."
  end

  def wikidata_item_filter(rows:, count_limit: 0, progress_bar:)
    wikidata_ids = []

    rows.each do |row|
      row = row.to_h
      # Skip if the Wikidata item ID is nil.
      next unless row.key?(:item)
      # Skip if it's used in less than count_limit Wikidata items.
      next if row[:count].to_i < count_limit

      wikidata_url = row[:item].to_s

      wikidata_ids << wikidata_url.gsub('http://www.wikidata.org/entity/', '')
    end

    progress_bar.total = wikidata_ids.length

    items = []
    # Filter invalid data.
    wikidata_ids.select! { |id| id.start_with?('Q') }

    (wikidata_ids.length / 48).floor.times do |index|
      start_from = index * 48
      wikidata_labels = WikidataHelper.get_labels(
        ids: wikidata_ids[start_from..start_from + 48],
        languages: 'en'
      )
      wikidata_labels.each do |id, wikidata_label|
        name = wikidata_label.dig('labels', 'en', 'value')
        # Skip items with no labels or no English label.
        wikidata_item = { wikidata_id: id, name: name } unless name.nil?
        items << wikidata_item if wikidata_item
      end
      # Add to the progress bar once every iteration.
      # Mark it as finished if it would otherwise overflow.
      if progress_bar.progress + 49 >= progress_bar.total
        progress_bar.finish
      else
        progress_bar.progress += 49
      end
    end

    item_names = items.map { |item| item&.dig(:name) } if ENV["DEBUG"]
    puts item_names.inspect if ENV["DEBUG"]

    return items
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
end
