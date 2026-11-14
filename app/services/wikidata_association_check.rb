# frozen_string_literal: true

require 'wikidata_sparql'

# Finds associations on games (platforms, genres, engines, developers,
# publishers and series) that the game's Wikidata item doesn't have. The
# `import:update:*` tasks only ever add associations from Wikidata, so one
# that was wrong and later fixed on Wikidata stays in vglist forever. This
# reports them for review. Read-only: it never writes to the games.
#
# Associations can also be added by hand in vglist, so a reported one isn't
# necessarily wrong.
#
# By default an association is only reported when the Wikidata item has at
# least one other value for that property, i.e. Wikidata lists, say, other
# platforms but not this one. That's the clearest sign the value was removed
# or replaced. Pass `include_empty: true` to also report associations for
# properties the item has no values for at all; those are noisier, since many
# items simply haven't had the property filled in yet, and deleted or merged
# items look the same.
#
# Every non-deprecated statement counts, not just best-rank ones, so a value
# that was outranked by a preferred statement isn't reported.
class WikidataAssociationCheck
  # Games per SPARQL round-trip. Each game returns a row per value of six
  # properties, so this is smaller than the label or type checks.
  CHUNK_SIZE = 500

  # Association name => Wikidata property, and how to load it. Series is a
  # column on games; the rest are join tables.
  ASSOCIATIONS = {
    platforms: { property: 'P400', join: :game_platforms, record: :platform },
    genres: { property: 'P136', join: :game_genres, record: :genre },
    engines: { property: 'P408', join: :game_engines, record: :engine },
    developers: { property: 'P178', join: :game_developers, record: :company },
    publishers: { property: 'P123', join: :game_publishers, record: :company },
    series: { property: 'P179', record: :series }
  }.freeze

  # An association the game's Wikidata item doesn't have. `wikidata_values`
  # is how many values the item has for the property.
  Result = Struct.new(
    :association,
    :game_id,
    :game_name,
    :game_wikidata_id,
    :record_id,
    :record_name,
    :record_wikidata_id,
    :wikidata_values,
    keyword_init: true
  )

  # @param [ActiveRecord::Relation] games the games to check; games without a
  #   Wikidata ID are skipped.
  # @param [Array<Symbol>] associations which of ASSOCIATIONS to check
  # @param [Boolean] include_empty also report associations for properties
  #   the item has no values for
  def initialize(games: Game.all, associations: ASSOCIATIONS.keys, include_empty: false)
    unknown = associations - ASSOCIATIONS.keys
    raise ArgumentError, "Unknown associations: #{unknown.join(', ')}" if unknown.any?

    @games = games.where.not(wikidata_id: nil)
    @associations = associations
    @include_empty = include_empty
  end

  # The number of games that will be checked.
  delegate :count, to: :@games

  # Check every game and yield each association Wikidata doesn't have.
  #
  # @param [Proc] on_chunk called with the number of games in each chunk once
  #   it's been checked, e.g. to advance a progress bar.
  # @yieldparam [Result] result
  # @return [void]
  def each_result(on_chunk: nil)
    @games.in_batches(of: CHUNK_SIZE) do |batch|
      games = batch.pluck(:id, :wikidata_id, :name)
      game_ids = games.map(&:first)
      wikidata_values = fetch_values(games.map { |_, wikidata_id, _| wikidata_id }.uniq)

      @associations.each do |association|
        records_by_game = vglist_records(association, game_ids)

        games.each do |game_id, game_wikidata_id, game_name|
          values = wikidata_values.dig(game_wikidata_id, association) || Set.new
          next if values.empty? && !@include_empty

          records_by_game.fetch(game_id, []).each do |record_id, record_name, record_wikidata_id|
            next if values.include?(record_wikidata_id)

            yield Result.new(
              association: association,
              game_id: game_id,
              game_name: game_name,
              game_wikidata_id: game_wikidata_id,
              record_id: record_id,
              record_name: record_name,
              record_wikidata_id: record_wikidata_id,
              wikidata_values: values.size
            )
          end
        end
      end

      on_chunk&.call(games.length)
    end
  end

  private

  # The game's associated records of one kind. Platforms, genres, engines,
  # companies and series all require a Wikidata ID.
  #
  # @return [Hash{Integer => Array<Array(Integer, String, Integer)>}] game ID
  #   => [[record ID, record name, record Wikidata ID], ...]
  def vglist_records(association, game_ids)
    config = ASSOCIATIONS.fetch(association)
    model = config[:record].to_s.classify.constantize
    table = model.table_name

    rows =
      if config[:join]
        Game.reflect_on_association(config[:join]).klass
            .joins(config[:record])
            .where(game_id: game_ids)
            .pluck(:game_id, "#{table}.id", "#{table}.name", "#{table}.wikidata_id")
      else
        Game.joins(config[:record])
            .where(id: game_ids)
            .pluck(:id, "#{table}.id", "#{table}.name", "#{table}.wikidata_id")
      end

    rows.group_by(&:first).transform_values { |game_rows| game_rows.map { |row| row.drop(1) } }
  end

  # Every non-deprecated value of the checked properties for the given items.
  #
  # @param [Array<Integer>] wikidata_ids
  # @return [Hash{Integer => Hash{Symbol => Set<Integer>}}] item => association
  #   => value Wikidata IDs
  def fetch_values(wikidata_ids)
    association_by_property = @associations.index_by { |association| ASSOCIATIONS.fetch(association)[:property] }
    values = Hash.new { |hash, item| hash[item] = Hash.new { |props, association| props[association] = Set.new } }

    WikidataSparql.query(values_query(wikidata_ids, association_by_property.keys)).each do |row|
      item = qid_to_int(row[:item])
      value = qid_to_int(row[:value])
      association = association_by_property[row[:property].to_s]
      next unless item && value && association

      values[item][association] << value
    end

    values
  end

  # One row per item, property and value. Uses statement nodes (p:/ps:)
  # rather than wdt: so normal-rank values that a preferred statement outranks
  # are still included; only deprecated statements are left out.
  def values_query(wikidata_ids, properties)
    branches = properties.map do |property|
      %({ ?item p:#{property} ?statement. ?statement ps:#{property} ?value. BIND("#{property}" AS ?property) })
    end

    <<~SPARQL
      SELECT ?item ?property ?value WHERE {
        VALUES ?item { #{wikidata_ids.map { |id| "wd:Q#{id}" }.join(' ')} }
        #{branches.join("\n  UNION ")}
        ?statement wikibase:rank ?rank.
        FILTER(?rank != wikibase:DeprecatedRank)
      }
    SPARQL
  end

  # @return [Integer, nil]
  def qid_to_int(uri)
    match = uri.to_s.match(%r{\Ahttp://www\.wikidata\.org/entity/Q(\d+)\z})
    match && match[1].to_i
  end
end
