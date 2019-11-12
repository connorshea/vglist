# typed: true
module Types
  class BaseObject < GraphQL::Schema::Object
    extend T::Sig
    include Pundit

    connection_type_class(Types::BaseConnectionObject)

    # User needs to be logged in to get anything from the API.
    sig { params(_object: T.untyped, context: GraphQL::Query::Context).returns(T::Boolean) }
    def self.authorized?(_object, context)
      raise GraphQL::ExecutionError, "You must be logged in to use the API." if context[:current_user].nil?

      raise GraphQL::ExecutionError, "Your token must have the 'read' scope to perform a query." unless context[:doorkeeper_scopes]&.include?('read')

      return true
    end
  end
end
