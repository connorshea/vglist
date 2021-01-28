# typed: strict
module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    extend T::Sig

    argument_class Types::BaseArgument
  end
end
