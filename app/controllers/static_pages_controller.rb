# typed: true
class StaticPagesController < ApplicationController
  layout :resolve_layout

  def about
    skip_authorization
  end

  def graphiql
    skip_authorization
  end

  # Renders the schema.graphql file for the GraphQL API, which is used by
  # GraphiQL to display the Docs Explorer.
  def graphql_schema
    skip_authorization
  end

  private

  def resolve_layout
    case action_name.to_sym
    when :about
      'application'
    when :graphiql
      'graphiql'
    when :graphql_schema
      false
    end
  end
end
