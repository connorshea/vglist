# frozen_string_literal: true

# Shared by the list resolvers behind the series, genre, platform, company and
# engine index pages (see `GameCountScopes` for the scopes they use).
module ResourceIndex
  module_function

  # An explicit mapping rather than public_send, so a sort value can only ever
  # call one of these scopes.
  #
  # @param relation [ActiveRecord::Relation] Records that include `GameCountScopes`.
  # @param sort_by [Symbol, nil] A `ResourceSortType` or `SeriesSortType` value.
  #   Without one, records are ordered by ID so that pagination is still stable.
  # @return [ActiveRecord::Relation]
  def sort(relation, sort_by)
    case sort_by
    when :most_games then relation.most_games
    when :alphabetical then relation.alphabetical
    when :recently_added then relation.recently_added
    else relation.order(:id)
    end
  end

  # Whether the nodes of a connection select any of these fields, so a
  # resolver only pays for per-row subqueries when a row shows them, and not
  # for e.g. the game form's pickers, which load names only.
  #
  # @param lookahead [GraphQL::Execution::Lookahead] The connection field's lookahead.
  # @param fields [Array<Symbol>]
  # @return [Boolean]
  def selects_any?(lookahead, fields)
    nodes = [lookahead.selection(:nodes), lookahead.selection(:edges).selection(:node)]
    nodes.any? { |node| fields.any? { |field| node.selects?(field) } }
  end
end
