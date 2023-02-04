# typed: false
module Types
  module SearchResultInterface
    include Types::BaseInterface

    description 'Search results returned by global search.'

    field :id, ID, null: false, description: 'The ID of the SearchResult record, probably not very useful most of the time.'
    field :content, String, null: false, description: 'The contents of the search result, typically the name or username of the corresponding record.'
    field :searchable_type, Enums::SearchableEnum, null: false, description: "The type of the corresponding record."
    field :searchable_id, ID, null: false, description: 'The ID of the corresponding record, e.g. the Game ID.'
  end
end
