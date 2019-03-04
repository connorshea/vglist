namespace :wikidata_import do
  require 'sparql/client'
  require 'wikidata_helper'

  desc "Import game developers and publishers from Wikidata"
  task :companies do
    puts "Importing game developers and publishers from Wikidata..."

    endpoint = "https://query.wikidata.org/sparql"
    client = SPARQL::Client.new(endpoint, :method => :get)

    rows = []
    rows.concat(client.query(developers_query))
    rows.concat(client.query(publishers_query))
    wikidata_ids = []

    puts "Importing up to #{rows.length} companies."
    companies = wikidata_item_filter(rows: rows)
    companies.uniq! { |company| company&.dig(:wikidata_id) }
    puts "Found #{companies.length} companies."
  end

  desc "Import game platforms from Wikidata"
  task :platforms do
    puts "Importing game platforms from Wikidata..."

    endpoint = "https://query.wikidata.org/sparql"
    client = SPARQL::Client.new(endpoint, :method => :get)

    rows = []
    rows.concat(client.query(platforms_query))

    wikidata_ids = []

    puts "Importing up to #{rows.length} platforms."
    platforms = wikidata_item_filter(rows: rows, count_limit: 80)
    platforms.uniq! { |platform| platform&.dig(:wikidata_id) }
    puts "Found #{platforms.length} platforms."
  end

  desc "Import game genres from Wikidata"
  task :genres do
    puts "Importing game genres from Wikidata..."

    endpoint = "https://query.wikidata.org/sparql"
    client = SPARQL::Client.new(endpoint, :method => :get)

    rows = []
    rows.concat(client.query(genres_query))

    puts "Importing up to #{rows.length} genres."
    genres = wikidata_item_filter(rows: rows, count_limit: 50)
    genres.uniq! { |genre| genre&.dig(:wikidata_id) }
    puts "Found #{genres.length} genres."
  end

  desc "Import game series from Wikidata"
  task :series do
    puts "Importing game series' from Wikidata..."

    endpoint = "https://query.wikidata.org/sparql"
    client = SPARQL::Client.new(endpoint, :method => :get)

    rows = []
    rows.concat(client.query(series_query))

    wikidata_ids = []

    puts "Importing up to #{rows.length} series'."
    series = wikidata_item_filter(rows: rows, count_limit: 1)
    series.uniq! { |series| series&.dig(:wikidata_id) }
    puts "Found #{series.length} series'."
  end

  def wikidata_item_filter(rows:, count_limit: 0)
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

    items = []
    # Filter invalid data.
    wikidata_ids.select! { |id| id.start_with?('Q') }

    (wikidata_ids.length / 48).floor.times do |index|
      start_from = index * 48
      wikidata_labels = WikidataHelper.get_labels(
        ids: wikidata_ids[start_from..start_from+48],
        languages: 'en'
      )
      wikidata_labels.each do |id, wikidata_label|
        name = wikidata_label.dig('labels', 'en', 'value')
        # Skip items with no labels or no English label.
        wikidata_item = { wikidata_id: id, name: name } unless name.nil?

        items << wikidata_item if wikidata_item
      end
    end

    item_names = items.map { |item| item&.dig(:name) } if ENV["DEBUG"]
    puts item_names.inspect if ENV["DEBUG"]

    return items
  end

  # Returns Wikidata items representing game developers.
  def developers_query
    return query('P178')
  end

  # Returns Wikidata items representing game publishers.
  def publishers_query
    return query('P123')
  end

  # Returns Wikidata items representing game platforms.
  def platforms_query
    return query('P400')
  end

  # Returns Wikidata items representing game genres.
  def genres_query
    return query('P136')
  end

  # Returns Wikidata items representing game series.
  def series_query
    return query('P179')
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
end
