# typed: strict

# Only enable these in development, GraphiQL isn't enabled in production yet.
if Rails.env.development?
  GraphiQL::Rails.config.headers['X-GraphiQL-Request'] = ->(_context) { "true" }
  GraphiQL::Rails.config.initial_query = <<~GRAPHQL
    query {
      game(id: 1) {
        id
        name
        releaseDate
      }
    }
  GRAPHQL
end
