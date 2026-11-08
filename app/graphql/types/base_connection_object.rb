# frozen_string_literal: true

class Types::BaseConnectionObject < GraphQL::Types::Relay::BaseConnection
  field :page_info, Types::PageInfoType, null: false, description: "Information to aid in pagination."
  field :total_count, Integer, null: false, description: "The total number of records returned by this query."

  node_nullable(false)

  def total_count
    items = object.items
    return items.count unless items.is_a?(ActiveRecord::Relation)

    # An unfiltered list of a model with a cached row count (e.g. the games
    # index with no filters set) has as many records as the table, so use the
    # cached count rather than counting the whole table again.
    return items.klass.cached_row_count if items.klass.respond_to?(:cached_row_count) && every_row?(items)

    unless items.group_values.any?
      # A relation that selects extra computed columns (e.g.
      # `Series.with_game_stats`) can't be counted by its select list, which
      # .count would try to do, so count rows instead.
      return items.select_values.many? ? items.count(:all) : items.count
    end

    # Grouped relations (e.g. the most_games and most_favorites scopes) return a
    # Hash with one entry per group from `.count`, which would load every
    # group into Ruby. Count the groups in Postgres instead. The order doesn't
    # change the count, so drop it.
    items.klass.from(items.unscope(:order), items.klass.table_name).count
  end

  private

  # Whether the relation lists each row of its table exactly once: no
  # conditions, inner joins, limit or custom FROM. Ordering, preloading and
  # extra selected columns don't change that, and neither does a LEFT JOIN
  # grouped by the primary key (e.g. `Game.most_favorites`), which still gives
  # one row per record.
  #
  # @param items [ActiveRecord::Relation]
  # @return [Boolean]
  def every_row?(items)
    return false unless items.where_clause.empty? && items.having_clause.empty?
    return false unless items.joins_values.empty? && items.from_clause.empty?
    return false if items.limit_value || items.offset_value

    return items.left_outer_joins_values.empty? if items.group_values.empty?

    primary_key = items.klass.primary_key
    items.group_values.map(&:to_s).in?([[primary_key], ["#{items.klass.table_name}.#{primary_key}"]])
  end
end
