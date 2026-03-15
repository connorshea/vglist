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
    argument :searchable_types, [Types::Enums::SearchableEnum], required: false do
      description 'The types of records that multisearch should return. By default, it will return all types of searchable records.'
      validates length: { minimum: 1 }
    end

    # Limit results per type to ensure type diversity. Without this,
    # a broad query like "the" returns thousands of games and drowns
    # out all other types.
    MAX_RESULTS_PER_TYPE = 25

    def resolve(query:, searchable_types: %w[Game Series Company Platform Engine Genre User])
      searchable_types.flat_map do |type|
        PgSearch.multisearch(query)
                .where(searchable_type: type)
                .limit(MAX_RESULTS_PER_TYPE)
                .to_a
      end
    end
  end
end
