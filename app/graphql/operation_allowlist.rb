# frozen_string_literal: true

# The set of GraphQL operations the API will execute for non-admin clients.
#
# The list lives in `config/graphql/operations.json` and is generated from the
# SPA's own queries and mutations by `pnpm --dir frontend run codegen` (see
# `frontend/codegen/operation-manifest.mjs`). Rejecting anything else means the
# GraphQL endpoint can only be used the way the SPA uses it, so a scraper can't
# hand-write a deeply nested query that the SPA would never send.
#
# Documents are compared structurally: both sides are parsed, their definitions
# sorted (an operation first, then fragments by name), and re-printed. This way
# whitespace, comments and fragment order in the request don't matter.
module OperationAllowlist
  MANIFEST_PATH = Rails.root.join('config/graphql/operations.json')
  EXECUTABLE_DEFINITIONS = [
    GraphQL::Language::Nodes::OperationDefinition,
    GraphQL::Language::Nodes::FragmentDefinition
  ].freeze

  # Longer documents are rejected without being parsed, so a huge request body
  # costs nothing to turn away. The SPA's largest operation is ~1 KB, and
  # spec/requests/graphql/operation_allowlist_spec.rb checks they all fit.
  MAX_QUERY_BYTES = 16 * 1024

  module_function

  # Whether the API should enforce the allowlist. On in production, off
  # elsewhere so specs and local development can send ad-hoc queries.
  def enabled?
    Rails.configuration.x.graphql_operation_allowlist
  end

  # @param query_string [String] The GraphQL document from the request.
  # @return [Boolean]
  def allowed?(query_string)
    return false if query_string.to_s.bytesize > MAX_QUERY_BYTES

    key = canonical(query_string)
    !key.nil? && canonical_documents.include?(key)
  end

  # @return [Hash{String => String}] Operation name => document.
  def operations
    @operations ||= JSON.parse(File.read(MANIFEST_PATH)).freeze
  end

  # The document a persisted document ID stands for, or nil if there is none.
  #
  # Over GET, the SPA sends `documentId=sha256:<hex>` instead of the document
  # (the name comes from the GraphQL over HTTP spec's persisted documents
  # proposal), where <hex> is the SHA-256 of the document exactly as it appears
  # in the manifest. `frontend/codegen/persisted-documents.mjs` computes the
  # same hashes for the SPA. Because the ID changes whenever the document does,
  # a CDN never serves a response for an old version of a query under a new
  # query's URL.
  #
  # @param document_id [String, nil]
  # @return [String, nil]
  def persisted_document(document_id)
    persisted_documents[document_id.to_s]
  end

  # @return [Hash{String => String}] Persisted document ID => document.
  def persisted_documents
    @persisted_documents ||= operations.values.index_by { |document| "sha256:#{Digest::SHA256.hexdigest(document)}" }.freeze
  end

  def canonical_documents
    @canonical_documents ||= operations.values.to_set { |document| canonical(document) }.freeze
  end

  # A normalized string for a GraphQL document, or nil if it can't be parsed.
  def canonical(query_string)
    document = GraphQL.parse(query_string.to_s)
    # GraphQL.parse also accepts SDL (`schema { ... }`, `type Foo { ... }`),
    # which the SPA never sends and which has no name to sort by.
    return nil unless document.definitions.all? { |definition| EXECUTABLE_DEFINITIONS.any? { |klass| definition.is_a?(klass) } }

    definitions = document.definitions.sort_by do |definition|
      [definition.is_a?(GraphQL::Language::Nodes::OperationDefinition) ? 0 : 1, definition.name.to_s]
    end

    document.merge(definitions: definitions).to_query_string
  rescue GraphQL::ParseError
    nil
  end
end
