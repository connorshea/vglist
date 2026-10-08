# frozen_string_literal: true

class Types::BaseConnectionObject < GraphQL::Types::Relay::BaseConnection
  field :page_info, Types::PageInfoType, null: false, description: "Information to aid in pagination."
  field :total_count, Integer, null: false, description: "The total number of records returned by this query."

  node_nullable(false)

  def total_count
    # `size` rather than `count`: a nested connection whose association was
    # preloaded (e.g. `platforms { totalCount }` on a page of games) counts
    # in memory instead of running a COUNT per parent. Unloaded relations
    # still COUNT in SQL.
    count = object.items.size
    # Grouped relations (e.g. most_games, most_followers scopes) return a
    # Hash from .count — use its length (number of distinct groups) instead.
    count.is_a?(Hash) ? count.length : count
  end
end
