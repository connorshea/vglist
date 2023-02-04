# typed: strict
class Types::PageInfoType < GraphQL::Types::Relay::PageInfo
  extend T::Sig

  field :page_size, Integer, null: false, description: "The max page size for a given set of nodes."

  sig { returns(Integer) }
  def page_size
    object.first || object.last || object.default_page_size || object.max_page_size || VideoGameListSchema.default_page_size || VideoGameListSchema.default_max_page_size
  end
end
