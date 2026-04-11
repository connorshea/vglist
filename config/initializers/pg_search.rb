# frozen_string_literal: true

# Postgres search configuration options for multisearch.
PgSearch.multisearch_options = {
  using: [:tsearch, :trigram]
}
