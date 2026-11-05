# frozen_string_literal: true

class Types::BaseConnectionObject < GraphQL::Types::Relay::BaseConnection
  field :page_info, Types::PageInfoType, null: false, description: "Information to aid in pagination."
  field :total_count, Integer, null: false, description: "The total number of records returned by this query."

  node_nullable(false)

  def total_count
    items = object.items
    # A relation that selects extra computed columns (e.g.
    # `Series.with_game_stats`) can't be counted by its select list, which
    # .count would try to do, so count rows instead.
    count = items.respond_to?(:select_values) && items.select_values.many? ? items.count(:all) : items.count
    # Grouped relations (e.g. most_games, most_followers scopes) return a
    # Hash from .count — use its length (number of distinct groups) instead.
    count.is_a?(Hash) ? count.length : count
  end
end
