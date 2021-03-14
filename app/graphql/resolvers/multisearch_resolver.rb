# typed: strict
module Resolvers
  class MultisearchResolver < Resolvers::BaseResolver
    type Types::SearchResultType.connection_type, null: false

    description <<~MARKDOWN
      Search for records matching a given string. Returns Companies, Engines,
      Games, Genres, Platforms, Series', and Users.

      Please always debounce/throttle requests to this endpoint. There's no
      reason to send a request for every letter a user types.
    MARKDOWN

    argument :query, String, required: true, description: 'The query to search for records with.'
    argument :searchable_types, [Types::SearchableEnum], required: false do
      description 'The types of records that multisearch should return. By default, it will return all types of searchable records.'
    end

    # Technically this should return `PgSearch::Document::RelationType`, but
    # SorbetRails doesn't seem to know about PgSearch::Document, so no types
    # for it exist.
    sig { params(query: String, searchable_types: T::Array[String]).returns(T.untyped) }
    def resolve(query:, searchable_types: %w[Game Series Company Platform Engine Genre User])
      PgSearch.multisearch(query)
              .where(searchable_type: searchable_types)
    end
  end
end
