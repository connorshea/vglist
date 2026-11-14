# frozen_string_literal: true

class Types::BaseConnectionObject < GraphQL::Types::Relay::BaseConnection
  field :page_info, Types::PageInfoType, null: false, description: "Information to aid in pagination."
  field :total_count, Integer, null: false, description: "The total number of records returned by this query."

  node_nullable(false)

  def total_count
    items = object.items
    return items.count unless items.is_a?(ActiveRecord::Relation)

    # The resolver marked this relation as listing every row of its table
    # (e.g. the games index with no filters set), so use the cached row count
    # rather than counting the whole table again. See `CachedRowCount`.
    return items.cached_total_count if items.respond_to?(:cached_total_count)

    # The resolver marked this relation as one of several that differ only in
    # a column the counts can be grouped by, so count them all in one query.
    # See `GamePurchaseStatusCounts`.
    return items.batched_total_count(context) if items.respond_to?(:batched_total_count)

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
end
