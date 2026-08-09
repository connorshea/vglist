# frozen_string_literal: true

module Resolvers
  class GlobalSearchResolver < Resolvers::BaseResolver
    type Types::SearchResultUnion.connection_type, null: false

    description <<~MARKDOWN
      Search for records matching a given string. Returns Companies, Engines,
      Games, Genres, Platforms, Series', and Users.

      Please always debounce/throttle requests to this endpoint. There's no
      reason to send a request for every letter a user types.
    MARKDOWN

    # Every searchable type, used as the default when the client doesn't
    # specify any. Also the upper bound on the length of `searchable_types`,
    # since asking for more than one of each type is meaningless.
    DEFAULT_SEARCHABLE_TYPES = %w[Game Series Company Platform Engine Genre User].freeze

    argument :query, String, required: true, description: 'The query to search for records with.'
    argument :searchable_types, [Types::Enums::SearchableEnum], required: false do
      description 'The types of records that multisearch should return. By default, it will return all types of searchable records. Duplicate types are ignored.'
      # `resolve` runs one full-text query per type, so cap the list at the
      # number of types that exist. Duplicates within that cap are deduped
      # below, so a request can never issue more than one query per type.
      validates length: { minimum: 1, maximum: DEFAULT_SEARCHABLE_TYPES.length }
    end

    # Limit results per type to ensure type diversity. Without this,
    # a broad query like "the" returns thousands of games and drowns
    # out all other types.
    MAX_RESULTS_PER_TYPE = 25

    def resolve(query:, searchable_types: DEFAULT_SEARCHABLE_TYPES)
      results = searchable_types.uniq.flat_map do |type|
        PgSearch.multisearch(query)
                .where(searchable_type: type)
                .limit(MAX_RESULTS_PER_TYPE)
                .to_a
      end

      preload_searchable_records(results)

      results
    end

    private

    # Batch-load the actual records for search result types that need
    # extra fields beyond what PgSearch::Document provides. Without
    # this, each field resolver would fire a separate query per result.
    def preload_searchable_records(results)
      grouped = results.group_by(&:searchable_type)

      if (game_docs = grouped['Game'])
        game_ids = game_docs.map(&:searchable_id)
        context[:preloaded_games] = Game.where(id: game_ids).includes(:developers).with_attached_cover.index_by(&:id)
      end

      if (user_docs = grouped['User'])
        user_ids = user_docs.map(&:searchable_id)
        context[:preloaded_users] = User.where(id: user_ids).with_attached_avatar.index_by(&:id)
      end
    end
  end
end
