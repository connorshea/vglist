# frozen_string_literal: true

# Rejects documents that select more than one of the unauthenticated auth
# mutations (signIn, signUp, requestPasswordReset).
#
# Without this, GraphQL aliasing lets a single HTTP request carry many
# attempts, e.g.
#
#   mutation { a: signIn(email: "x", password: "1") { token }
#              b: signIn(email: "x", password: "2") { token } ... }
#
# which multiplies password guesses (and bcrypt CPU) or password-reset emails
# per request and sidesteps per-request rate limiting.
class Analyzers::AuthMutationLimitAnalyzer < GraphQL::Analysis::Analyzer
  LIMITED_FIELDS = %w[signIn signUp requestPasswordReset].freeze
  LIMIT = 1

  def initialize(query_or_multiplex)
    super
    @count = 0
  end

  def on_enter_field(_node, _parent, visitor)
    return if visitor.skipping?

    field = visitor.field_definition
    return unless field&.owner == Types::MutationType
    return unless LIMITED_FIELDS.include?(field.graphql_name)

    @count += 1
  end

  def result
    return if @count <= LIMIT

    GraphQL::AnalysisError.new(
      "Only one of #{LIMITED_FIELDS.join(', ')} may be used per request."
    )
  end
end
