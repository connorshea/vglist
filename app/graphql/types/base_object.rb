# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    include Pundit::Authorization

    connection_type_class(Types::BaseConnectionObject)

    # Allow unauthenticated users to read public data.
    # When a user IS authenticated, check that they are not banned
    # and that their OAuth token has the required scopes.
    def self.authorized?(_object, context)
      if context[:current_user].present?
        raise GraphQL::ExecutionError, "The user that owns this token has been banned." if context[:current_user].banned?

        # Make sure the doorkeeper scopes include read.
        # Skip this check if the user is using token authentication.
        raise GraphQL::ExecutionError, "Your token must have the 'read' scope to perform a query." if !context[:token_auth] &&
                                                                                                      context[:doorkeeper_scopes] &&
                                                                                                      !context[:doorkeeper_scopes]&.include?('read')
      end

      return true
    end
  end
end
