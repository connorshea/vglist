# typed: strict
module Types
  module BaseInterface
    include GraphQL::Schema::Interface

    connection_type_class(Types::BaseConnectionObject)
  end
end
