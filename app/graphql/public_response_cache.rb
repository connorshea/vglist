# frozen_string_literal: true

# Caches whole GraphQL responses for the few operations every visitor to the
# home page sends, as long as the response can't depend on who is asking.
#
# Each response is cached for a few minutes in Rails.cache, so new games,
# library additions and cover changes show up on the home page after at most
# EXPIRES_IN. Cover URLs are public R2 URLs that don't expire, so they're safe
# to cache.
#
# The set of keys is small and fixed: an operation is only cacheable with the
# variables the home page (including its new releases shelf) and the first page of the games index send. Anything
# else (other filters, later pages, a signed-in user's game tiles) runs
# normally, so a client can't fill the cache with arbitrary variations and
# evict the Rack::Attack counters that share the store.
module PublicResponseCache
  EXPIRES_IN = 5.minutes

  # The operations whose responses can be cached, with the right variables.
  # Signed-out visitors send these as GET requests, so Cloudflare can cache
  # them too (see GraphqlController#allow_shared_caching). The SPA gets their
  # persisted document IDs from codegen, whose config in frontend/codegen.ts
  # must list the same operations.
  OPERATIONS = %w[GetGamesIndex GetGamesIndexFilters GetHeroCovers GetNewReleases].freeze

  # The largest `first` that's cached for GetGamesIndex: the games index's
  # page size. The home page shelves ask for 6.
  MAX_GAMES_PAGE = 36

  # Filters that make GetGamesIndex uncacheable when set. `excludeLibrary`
  # depends on the user, the rest would multiply the number of keys.
  GAMES_INDEX_FILTERS = %w[after onPlatform byGenre byEngine fromYear toYear excludeLibrary].freeze

  module_function

  # The cache key for this request's response, or nil if it mustn't be cached.
  #
  # @param query [String] The GraphQL document from the request.
  # @param operation_name [String, nil]
  # @param variables [Hash, ActionController::Parameters]
  # @param user [User, nil] The signed-in user, if any.
  # @return [String, nil]
  def key_for(query, operation_name, variables, user)
    variables = variables.respond_to?(:to_unsafe_h) ? variables.to_unsafe_h : variables.to_h
    parts = cacheable_parts(operation_name, variables, user)
    return nil if parts.nil?
    # The operation name is chosen by the client, so check that the document
    # really is the SPA's operation of that name.
    return nil unless OperationAllowlist.canonical(query) == canonical_document(operation_name)

    ['graphql_public_response', ENV.fetch('GIT_COMMIT_SHA', nil), operation_name, *parts].join('/')
  end

  # @return [Array, nil] The variables that identify the response, or nil if
  #   the operation isn't cacheable with these variables.
  def cacheable_parts(operation_name, variables, user)
    case operation_name
    when 'GetHeroCovers'
      []
    when 'GetGamesIndexFilters'
      # The platform/genre/engine lookups are only cached when they're off.
      [] if %w[hasPlatform hasGenre hasEngine].none? { |name| variables[name] }
    when 'GetGamesIndex'
      games_index_parts(variables, user)
    when 'GetNewReleases'
      new_releases_parts(variables, user)
    end
  end

  # Game tiles carry the signed-in user's library status, so only signed-out
  # responses are cached.
  def games_index_parts(variables, user)
    return nil unless user.nil?
    return nil unless GAMES_INDEX_FILTERS.all? { |name| variables[name].blank? }

    first = variables['first']
    return nil unless first.is_a?(Integer) && first.between?(1, MAX_GAMES_PAGE)

    sort_by = variables['sortBy']
    return nil unless sort_by.nil? || Types::Enums::GameSortType.values.key?(sort_by)

    with_count = variables['withCount']
    return nil unless [true, false].include?(with_count)

    [first, sort_by || 'default', with_count]
  end

  # Like the games index, the new releases tiles carry the signed-in user's
  # library status, so only signed-out responses are cached.
  def new_releases_parts(variables, user)
    return nil unless user.nil?

    first = variables['first']
    [first] if first.is_a?(Integer) && first.between?(1, NewReleases::MAX)
  end

  def canonical_document(operation_name)
    @canonical_documents ||= {}
    @canonical_documents[operation_name] ||= OperationAllowlist.canonical(OperationAllowlist.operations.fetch(operation_name))
  end
end
