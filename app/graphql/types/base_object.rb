# typed: strict
module Types
  class BaseObject < GraphQL::Schema::Object
    extend T::Sig
    include Pundit

    connection_type_class(Types::BaseConnectionObject)

    # User needs to be logged in to get anything from the API.
    sig { params(_object: T.untyped, context: GraphQL::Query::Context).returns(T::Boolean) }
    def self.authorized?(_object, context)
      raise GraphQL::ExecutionError, "You must be logged in to use the API." if context[:current_user].nil?

      # Make sure the doorkeeper scopes include read.
      # Skip this check if the user is using token authentication or
      # if the request comes from GraphiQL.
      raise GraphQL::ExecutionError, "Your token must have the 'read' scope to perform a query." if !context[:token_auth] &&
                                                                                                    !context[:doorkeeper_scopes]&.include?('read') &&
                                                                                                    !context[:graphiql_override]

      return true
    end
  end
end
