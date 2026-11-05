# frozen_string_literal: true

# Rejects documents that pass a negative `first:` or `last:` to a connection.
#
# Connection complexity is the page size times the cost of each record, so a
# negative page size makes a subtree's score negative. That can offset
# expensive sibling selections and sneak a query under max_complexity, e.g.
#
#   { a: games(first: -100000) { nodes { id } } b: <something expensive> }
#
# A negative page size never means anything useful, so refuse it outright.
class Analyzers::NonNegativePaginationAnalyzer < GraphQL::Analysis::Analyzer
  PAGINATION_ARGUMENTS = %i[first last].freeze

  def initialize(query_or_multiplex)
    super
    @negative = []
  end

  def on_enter_field(node, _parent, visitor)
    return if visitor.skipping?

    field = visitor.field_definition
    return unless field&.connection?

    arguments = visitor.arguments_for(node, field)
    return unless arguments.respond_to?(:[])

    PAGINATION_ARGUMENTS.each do |name|
      value = arguments[name]
      @negative << "#{field.path}(#{name}: #{value})" if value.is_a?(Integer) && value.negative?
    end
  end

  def result
    return if @negative.empty?

    GraphQL::AnalysisError.new("Pagination arguments can't be negative: #{@negative.join(', ')}.")
  end
end
