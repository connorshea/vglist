# typed: strict
module Resolvers
  class GlobalSearchResolver < Resolvers::BaseResolver
    type Types::SearchResultUnion.connection_type, null: false

    description <<~MARKDOWN
      Search for records matching a given string. Returns Companies, Engines,
      Games, Genres, Platforms, Series', and Users.

      Please always debounce/throttle requests to this endpoint. There's no
      reason to send a request for every letter a user types.
    MARKDOWN

    argument :query, String, required: true, description: 'The query to search for records with.'
    argument :searchable_types, [Types::SearchableEnum], required: false do
      description 'The types of records that multisearch should return. By default, it will return all types of searchable records.'
      validates length: { minimum: 1 }
    end
    argument :page, Int, required: false, default_value: 1, description: "The page of records to get, this is a gross hack and I'm sorry." do
      validates numericality: { greater_than: 0 }
    end

    # Technically this should return `PgSearch::Document::RelationType`, but
    # SorbetRails doesn't seem to know about PgSearch::Document, so no types
    # for it exist.
    sig { params(query: String, page: Integer, searchable_types: T::Array[String]).returns(T.untyped) }
    def resolve(query:, page:, searchable_types: %w[Game Series Company Platform Engine Genre User])
      PgSearch.multisearch(query)
              .where(searchable_type: searchable_types)
              .page(page)
              .per(15)
    end
  end
end
