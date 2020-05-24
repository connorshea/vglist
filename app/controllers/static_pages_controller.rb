# typed: true
class StaticPagesController < ApplicationController
  layout :resolve_layout

  def about
    skip_authorization
  end

  def graphiql
    skip_authorization
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
