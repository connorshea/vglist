# typed: strict
class Types::BaseConnectionObject < GraphQL::Types::Relay::BaseConnection
  extend T::Sig

  field :page_info, Types::PageInfoType, null: false, description: "Information to aid in pagination."
  field :total_count, Integer, null: false, description: "The total number of records returned by this query."

  node_nullable(false)

  sig { returns(Integer) }
  def total_count
    object.items.count
  end
end
