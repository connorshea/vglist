class StaticPagesController < ApplicationController
  layout :resolve_layout

  def about
    skip_authorization
  end

  def graphiql
    @email = current_user&.email
    @email ||= "user@example.com"
    @token = current_user&.api_token
    @token ||= "API_TOKEN_HERE"

    skip_authorization
  end

  def opensearch
    skip_authorization
    render layout: false
  end

  private

  def resolve_layout
    case action_name.to_sym
    when :about
      'application'
    when :graphiql
      'graphiql'
    end
  end
end
