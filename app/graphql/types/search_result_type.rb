# typed: true
module Types
  class SearchResultType < Types::BaseObject
    description "Represents search results from PgSearch queries."

    field :id, ID, null: false, description: 'The ID of the SearchResult record, probably not very useful most of the time.'
    field :content, String, null: false, description: 'The contents of the search result, typically the name or username of the corresponding record.'
    field :searchable_type, SearchableEnum, null: false, description: "The type of the corresponding record."
    field :searchable_id, ID, null: false, description: 'The ID of the corresponding record, e.g. the Game ID.'
  end
end
