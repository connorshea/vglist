# frozen_string_literal: true

class Types::BaseConnectionObject < GraphQL::Types::Relay::BaseConnection
  field :page_info, Types::PageInfoType, null: false, description: "Information to aid in pagination."
  field :total_count, Integer, null: false, description: "The total number of records returned by this query."

  node_nullable(false)

  def total_count
    items = object.items
    return items.count unless items.is_a?(ActiveRecord::Relation) && items.group_values.any?

    # Grouped relations (e.g. the most_games and most_owners scopes) return a
    # Hash with one entry per group from `.count`, which would load every
    # group into Ruby. Count the groups in Postgres instead. The order doesn't
    # change the count, so drop it.
    items.klass.from(items.unscope(:order), items.klass.table_name).count
  end
end
