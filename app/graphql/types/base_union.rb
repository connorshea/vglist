# typed: true
module Types
  class BaseUnion < GraphQL::Schema::Union
    connection_type_class(Types::BaseConnectionObject)
  end
end
