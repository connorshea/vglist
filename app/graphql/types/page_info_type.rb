# typed: true
class Types::PageInfoType < GraphQL::Types::Relay::PageInfo
  field :page_size, Integer, null: false, description: "page size"

  def page_size
    VideoGameListSchema.default_max_page_size
  end
end
