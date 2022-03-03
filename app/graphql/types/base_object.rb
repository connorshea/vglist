# typed: strict
module Types
  class BaseObject < GraphQL::Schema::Object
    extend T::Sig
    include Pundit::Authorization

    connection_type_class(Types::BaseConnectionObject)

    # User needs to be logged in to get anything from the API.
    sig { params(_object: T.untyped, context: GraphQL::Query::Context).returns(T::Boolean) }
    def self.authorized?(_object, context)
      raise GraphQL::ExecutionError, "You must be logged in to use the API." if context[:current_user].nil?
      raise GraphQL::ExecutionError, "The user that owns this token has been banned." if context[:current_user]&.banned?

      # Make sure the doorkeeper scopes include read.
      # Skip this check if the user is using token authentication.
      raise GraphQL::ExecutionError, "Your token must have the 'read' scope to perform a query." if !context[:token_auth] &&
                                                                                                    context[:doorkeeper_scopes] &&
                                                                                                    !context[:doorkeeper_scopes]&.include?('read')

      return true
    end
  end
end
