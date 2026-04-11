class Types::BaseConnectionObject < GraphQL::Types::Relay::BaseConnection
  field :page_info, Types::PageInfoType, null: false, description: "Information to aid in pagination."
  field :total_count, Integer, null: false, description: "The total number of records returned by this query."

  node_nullable(false)

  def total_count
    count = object.items.count
    # Grouped relations (e.g. most_games, most_followers scopes) return a
    # Hash from .count — use its length (number of distinct groups) instead.
    count.is_a?(Hash) ? count.length : count
  end
end
