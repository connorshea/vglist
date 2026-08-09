# frozen_string_literal: true

# Works out which associations a `GameType` connection actually needs, based on
# the fields the client selected, so that resolvers returning lists of games can
# preload exactly those and nothing more.
#
# Preloading every association unconditionally costs ~19 queries even for a
# query as narrow as `{ games { nodes { id name } } }`, which is a shape the SPA
# sends often.
module GamePreloads
  # GameType field name => the association to preload for it.
  #
  # `cover_url` is deliberately absent: it needs `with_attached_cover`, which
  # preloads `blob: { variant_records: { image_attachment: :blob } }` on top of
  # the attachment. A plain `includes(cover_attachment: :blob)` would leave the
  # variant record lookup to fire once per game.
  FIELD_PRELOADS = {
    series: :series,
    developers: :developers,
    publishers: :publishers,
    engines: :engines,
    genres: :genres,
    platforms: :platforms,
    steam_app_ids: :steam_app_ids
  }.freeze

  # Preload only the associations the query selected.
  #
  # @param relation [ActiveRecord::Relation] A relation of games.
  # @param lookahead [GraphQL::Execution::Lookahead] The lookahead for the
  #   connection field itself, not for its nodes.
  # @return [ActiveRecord::Relation]
  def self.apply(relation, lookahead)
    nodes = node_lookaheads(lookahead)
    # Nothing under `nodes`/`edges` was selected, e.g. a `totalCount`-only
    # query, so no game records will be rendered at all.
    return relation if nodes.empty?

    selected = ->(field) { nodes.any? { |node| node.selects?(field) } }

    includes = FIELD_PRELOADS.filter_map { |field, association| association if selected.call(field) }
    # `includes` raises if called without arguments.
    relation = relation.includes(*includes) if includes.any?
    relation = relation.with_attached_cover if selected.call(:cover_url)

    relation
  end

  # A connection's fields are selected through `nodes`, through
  # `edges { node }`, or through both at once, so both have to be consulted.
  # Chaining `selection` is safe when a selection is absent — it returns a null
  # lookahead, which reports itself as not selected.
  #
  # @param lookahead [GraphQL::Execution::Lookahead]
  # @return [Array<GraphQL::Execution::Lookahead>]
  def self.node_lookaheads(lookahead)
    [
      lookahead.selection(:nodes),
      lookahead.selection(:edges).selection(:node)
    ].select(&:selected?)
  end
  private_class_method :node_lookaheads
end
