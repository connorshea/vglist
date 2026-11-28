# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    argument_class Types::BaseArgument

    MAX_SEARCH_QUERY_LENGTH = 200

    # The `query` argument shared by the search resolvers. Search terms often
    # come straight from a URL (`/search?query=`), so reject input that would
    # otherwise raise inside pg_search and surface as a 500.
    def self.search_query_argument(description)
      argument :query, String,
        required: true,
        description: description,
        validates: { length: { maximum: MAX_SEARCH_QUERY_LENGTH } },
        prepare: lambda { |query, _context|
          raise GraphQL::ExecutionError, 'query must not contain null bytes.' if query.include?("\u0000")

          query
        }
    end
  end
end
