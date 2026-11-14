# frozen_string_literal: true

module VglistSearch
  # Queries shorter than this skip trigram matching. A two- or three-letter
  # query like "to" or "the" shares a trigram with most documents, so the
  # trigram GIN index hands back nearly every row to recheck and rank, which
  # took 1-3 seconds in production. Trigram similarity can't find typos in a
  # query that short anyway, so prefix tsearch alone ("to" matches "Tomb",
  # "Tony Hawk") gives better results and stays on the tsvector index.
  SHORT_QUERY_LENGTH = 4

  def self.multisearch_options(query)
    if query.to_s.strip.length < SHORT_QUERY_LENGTH
      { query: query, using: { tsearch: { prefix: true } } }
    else
      { query: query, using: [:tsearch, :trigram] }
    end
  end
end

# Postgres search configuration options for multisearch.
PgSearch.multisearch_options = ->(query, *) { VglistSearch.multisearch_options(query) }
