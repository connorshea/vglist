# typed: true
class Types::PageInfoType < GraphQL::Types::Relay::PageInfo
  field :total, Integer, null: false, description: "Total number of items for this result set."

  # TODO: Make this work properly (right now the )
  def total
    object.nodes.size
  end
end
